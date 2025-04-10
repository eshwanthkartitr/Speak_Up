import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ModelHelper {
  // This utility class provides simplified methods to work with ML models

  // Maps to store label mappings
  static Map<String, int> _labelToIndexMap = {};
  static Map<int, String> _indexToLabelMap = {};
  static List<String>? _cachedLabels;

  static Interpreter? _interpreter;

  // Character sets indices ranges
  static final Map<String, Map<String, int>> _characterSetRanges = {
    'Tamil': {'start': 0, 'end': 247}, // Tamil characters
    'Arabic': {'start': 275, 'end': 305}, // Arabic characters
    'English': {'start': 248, 'end': 274}, // English characters and symbols
  };

  // Load labels from the assets
  static Future<List<String>> loadLabels(String path) async {
    try {
      if (_cachedLabels != null) {
        return _cachedLabels!;
      }

      final labelsData = await rootBundle.loadString(path);
      final labels = labelsData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .toList();

      // Create label-to-index mapping
      for (int i = 0; i < labels.length; i++) {
        _labelToIndexMap[labels[i]] = i;
        _indexToLabelMap[i] = labels[i];
      }

      _cachedLabels = labels;
      return labels;
    } catch (e) {
      print('Error loading labels: $e');
      return [];
    }
  }

  // Get label for a given index
  static String getLabel(int index) {
    // Check if we have a mapping for this index
    if (_indexToLabelMap.containsKey(index)) {
      return _indexToLabelMap[index]!;
    }

    // If no label is found, return a default value
    return 'Background';
  }

  static Future<bool> loadModel() async {
    try {
      if (_interpreter != null) {
        return true; // Model already loaded
      }

      // Convert PyTorch model to TFLite format on first use
      final modelPath = await copyModelToDocuments(
          'assets/models/mobilenetv3_simple.tflite',
          'mobilenetv3_simple.tflite');

      if (modelPath == null) {
        print('Failed to copy model to documents directory');
        return false;
      }

      // Load the model
      final interpreterOptions = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromFile(File(modelPath),
          options: interpreterOptions);

      print('Model loaded successfully from: $modelPath');
      return true;
    } catch (e) {
      print('Error loading model: $e');
      return false;
    }
  }

  // Copy model file from assets to app documents directory
  static Future<String?> copyModelToDocuments(
      String assetPath, String filename) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final modelPath = '${appDir.path}/$filename';

      // Check if model exists, if not, copy it
      final modelFile = File(modelPath);
      if (!modelFile.existsSync()) {
        final ByteData data = await rootBundle.load(assetPath);
        final Uint8List bytes = data.buffer.asUint8List();
        await modelFile.writeAsBytes(bytes);
      }

      return modelPath;
    } catch (e) {
      print('Error copying model: $e');
      return null;
    }
  }

  // Process camera image into an image that can be used for inference
  static Future<img.Image?> processCameraImage(CameraImage cameraImage) async {
    try {
      // Convert YUV to RGB
      final int width = cameraImage.width;
      final int height = cameraImage.height;

      final int uvRowStride = cameraImage.planes[1].bytesPerRow;
      final int? uvPixelStride = cameraImage.planes[1].bytesPerPixel;

      if (uvPixelStride == null) {
        throw Exception('UV pixel stride is null');
      }

      // Create image buffer with correct format
      final image = img.Image(width: width, height: height);

      // Fill image buffer with plane data
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
          final int index = y * width + x;

          final yp = cameraImage.planes[0].bytes[index];
          final up = cameraImage.planes[1].bytes[uvIndex];
          final vp = cameraImage.planes[2].bytes[uvIndex];

          // Calculate RGB values
          int r = (yp + vp * 1436 ~/ 1024 - 179).clamp(0, 255);
          int g = (yp - up * 46549 ~/ 131072 + 44 - vp * 93604 ~/ 131072 + 91)
              .clamp(0, 255);
          int b = (yp + up * 1814 ~/ 1024 - 227).clamp(0, 255);

          // Save RGB value using the appropriate method for the current version of the image package
          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      return image;
    } catch (e) {
      print('Error processing camera image: $e');
      return null;
    }
  }

  static List<List<List<double>>> prepareImageForInference(img.Image image) {
    // Resize image to model input size (assuming 224x224 for MobileNetV3)
    final resizedImage = img.copyResize(image, width: 224, height: 224);

    // Initialize the input tensor
    final List<List<List<double>>> input = List.generate(
      224,
      (y) => List.generate(
        224,
        (x) {
          try {
            // Get pixel color
            final pixel = resizedImage.getPixel(x, y);

            // Extract RGB components
            int r, g, b;

            // The pixel is always an img.Pixel in newer versions, and we need to convert num to int
            if (pixel is img.Pixel) {
              r = pixel.r.toInt();
              g = pixel.g.toInt();
              b = pixel.b.toInt();
            } else {
              // This should never happen with newer versions, but just in case
              r = 0;
              g = 0;
              b = 0;
              print('Unexpected pixel type: ${pixel.runtimeType}');
            }

            // Normalize pixel values to [-1, 1] for MobileNetV3
            return [
              (r / 127.5) - 1.0,
              (g / 127.5) - 1.0,
              (b / 127.5) - 1.0,
            ];
          } catch (e) {
            // Handle any errors gracefully
            print('Error processing pixel at ($x,$y): $e');
            return [0.0, 0.0, 0.0]; // Return black pixel as fallback
          }
        },
      ),
    );

    return input;
  }

  // Perform inference on the processed image
  static Future<List<double>> runInference(img.Image image) async {
    if (_interpreter == null) {
      final modelLoaded = await loadModel();
      if (!modelLoaded) {
        throw Exception('Failed to load interpreter');
      }
    }

    if (_interpreter == null) {
      throw Exception('Interpreter is still null after loading attempt');
    }

    // Prepare input data
    final input = prepareImageForInference(image);

    // Prepare output tensor with the correct shape
    final output = List<double>.filled(306, 0); // 306 classes

    try {
      // Run inference with properly shaped input/output
      _interpreter!.run(input, output);
      return output;
    } catch (e) {
      print('Error during inference: $e');
      throw Exception('Inference failed: $e');
    }
  }

  // Get predicted character from output
  static String getPredictedCharacter(List<double> output,
      {String characterSet = 'Tamil'}) {
    // Get the range for the specified character set
    final range = _characterSetRanges[characterSet];
    if (range == null) {
      throw Exception('Invalid character set: $characterSet');
    }

    // Find the index with maximum probability within the range
    double maxProb = -1;
    int maxIdx = -1;

    for (int i = range['start']!; i <= range['end']!; i++) {
      if (i < output.length && output[i] > maxProb) {
        maxProb = output[i];
        maxIdx = i;
      }
    }

    // Return the corresponding label
    if (maxIdx >= 0) {
      return getLabel(maxIdx);
    }

    return '';
  }

  // Get transliteration for a character
  static String _getTransliteration(String character) {
    // Extract transliteration from character format: "அ(a)" or "Alef(ا)"
    final regex = RegExp(r'\((.*?)\)');
    final match = regex.firstMatch(character);
    return match != null ? match.group(1)! : '';
  }

  // Generate word suggestions based on the predicted character with synonymic query expansion
  static List<String> generateWordSuggestions(String character,
      {String characterSet = 'Tamil'}) {
    if (character.isEmpty) return [];

    // Extract the base character without the transliteration
    final baseCharMatch = RegExp(r'(.*?)\(').firstMatch(character);
    final baseChar =
        baseCharMatch != null ? baseCharMatch.group(1)! : character;

    // Extract the transliteration for search expansion
    final transliteration = _getTransliteration(character);

    // Set of suggestions to return
    Set<String> suggestions = {};

    if (characterSet == 'Tamil') {
      suggestions.addAll(_generateTamilSuggestions(baseChar, transliteration));
    } else if (characterSet == 'Arabic') {
      suggestions.addAll(_generateArabicSuggestions(baseChar, transliteration));
    } else {
      // English
      suggestions.addAll(_generateEnglishSuggestions(baseChar));
    }

    // If we have too few suggestions, add some common words
    if (suggestions.length < 4) {
      if (characterSet == 'Tamil') {
        suggestions.addAll([
          'வணக்கம் (Hello)',
          'நன்றி (Thank you)',
          'காலை வணக்கம் (Good morning)',
          'மாலை வணக்கம் (Good evening)'
        ]);
      } else if (characterSet == 'Arabic') {
        suggestions.addAll([
          'سلام (Peace)',
          'شكرا (Thank you)',
          'من فضلك (Please)',
          'أهلا وسهلا (Welcome)'
        ]);
      } else {
        // English
        suggestions.addAll(['Hello', 'Thanks', 'Good', 'Welcome']);
      }
    }

    // Return a list with up to 8 suggestions
    return suggestions.take(8).toList();
  }

  // Helper method to generate Tamil word suggestions
  static Set<String> _generateTamilSuggestions(
      String baseChar, String transliteration) {
    // Dictionary of Tamil words based on characters
    final Map<String, List<String>> tamilDictionary = {
      // Vowels
      'அ': [
        'அம்மா (Mother)',
        'அப்பா (Father)',
        'அரசு (Government)',
        'அன்பு (Love)',
        'அழகு (Beauty)'
      ],
      'ஆ': [
        'ஆடு (Goat)',
        'ஆறு (River)',
        'ஆசை (Desire)',
        'ஆண்டு (Year)',
        'ஆலயம் (Temple)'
      ],
      'இ': [
        'இசை (Music)',
        'இதயம் (Heart)',
        'இரவு (Night)',
        'இலை (Leaf)',
        'இளம் (Young)'
      ],
      'ஈ': [
        'ஈரம் (Wet)',
        'ஈட்டி (Spear)',
        'ஈசல் (Fly)',
        'ஈர்ப்பு (Attraction)',
        'ஈவு (Mercy)'
      ],
      'உ': [
        'உணவு (Food)',
        'உயிர் (Life)',
        'உறவு (Relation)',
        'உழைப்பு (Work)',
        'உள்ளம் (Mind)'
      ],
      'ஊ': [
        'ஊர் (Village)',
        'ஊழல் (Corruption)',
        'ஊக்கம் (Enthusiasm)',
        'ஊமை (Mute)',
        'ஊனம் (Disability)'
      ],
      'எ': [
        'எழுத்து (Letter)',
        'எறும்பு (Ant)',
        'எண் (Number)',
        'எரி (Burn)',
        'எலி (Rat)'
      ],
      'ஏ': [
        'ஏணி (Ladder)',
        'ஏரி (Lake)',
        'ஏழை (Poor)',
        'ஏடு (Book)',
        'ஏமாற்று (Deceive)'
      ],
      'ஐ': [
        'ஐந்து (Five)',
        'ஐயம் (Doubt)',
        'ஐக்கியம் (Unity)',
        'ஐவர் (Five People)',
        'ஐப்பசி (Tamil Month)'
      ],
      'ஒ': [
        'ஒளி (Light)',
        'ஒற்றுமை (Unity)',
        'ஒலி (Sound)',
        'ஒப்பந்தம் (Agreement)',
        'ஒதுக்கு (Exclude)'
      ],
      'ஓ': [
        'ஓடு (Run)',
        'ஓவியம் (Painting)',
        'ஓசை (Noise)',
        'ஓடை (Stream)',
        'ஓய்வு (Rest)'
      ],

      // Consonants
      'க': [
        'கல் (Stone)',
        'கதவு (Door)',
        'கடல் (Sea)',
        'காடு (Forest)',
        'கை (Hand)'
      ],
      'ங': [
        'ஙனம் (This way)',
        'ஙாயன் (The fat man)',
        'ஙோடு (Bank)',
        'ஙிலை (Place)',
        'ஙாகம் (Dragon)'
      ],
      'ச': [
        'சத்தம் (Sound)',
        'சந்தை (Market)',
        'சாவி (Key)',
        'சிறகு (Wing)',
        'சிரிப்பு (Laugh)'
      ],
      'ஞ': [
        'ஞாயிறு (Sunday/Sun)',
        'ஞானம் (Knowledge)',
        'ஞாபகம் (Memory)',
        'ஞாலம் (World)',
        'ஞமலி (Wolf)'
      ],
      'ட': [
        'டமாரம் (Drum)',
        'டாக்டர் (Doctor)',
        'டிக்கெட் (Ticket)',
        'டீ (Tea)',
        'டவுன் (Town)'
      ],
      'ண': [
        'ணன் (A good person)',
        'ணகை (Smile)',
        'ணவு (Meal)',
        'ணயம் (Good)',
        'ணடை (Style)'
      ],
      'த': [
        'தமிழ் (Tamil)',
        'தண்ணீர் (Water)',
        'தலை (Head)',
        'தாய் (Mother)',
        'தீ (Fire)'
      ],
      'ந': [
        'நட்பு (Friendship)',
        'நாடு (Country)',
        'நீர் (Water)',
        'நிலா (Moon)',
        'நேரம் (Time)'
      ],
      'ப': [
        'பல் (Tooth)',
        'பறவை (Bird)',
        'பாடம் (Lesson)',
        'பூமி (Earth)',
        'பேச்சு (Speech)'
      ],
      'ம': [
        'மலர் (Flower)',
        'மரம் (Tree)',
        'மழை (Rain)',
        'மனம் (Mind)',
        'மாலை (Evening/Garland)'
      ],
      'ய': [
        'யானை (Elephant)',
        'யோகம் (Yoga)',
        'யுத்தம் (War)',
        'யாழ் (Harp)',
        'யாத்திரை (Journey)'
      ],
      'ர': [
        'ரசம் (Juice/Soup)',
        'ரயில் (Train)',
        'ரத்தம் (Blood)',
        'ரவி (Sun)',
        'ராஜா (King)'
      ],
      'ல': [
        'லட்சியம் (Ambition)',
        'லாபம் (Profit)',
        'லீலை (Play)',
        'லேசு (Easy)',
        'லைட் (Light)'
      ],
      'வ': [
        'வயல் (Field)',
        'வாழை (Banana)',
        'விண் (Sky)',
        'வீடு (House)',
        'வெற்றி (Victory)'
      ],
      'ழ': [
        'ழகரம் (Letter ழ)',
        'ழவி (Child)',
        'ழரி (Ocean)',
        'ழலை (Child Speech)',
        'ழை (Cave/Entrance)'
      ],
      'ள': [
        'ளம் (Youth)',
        'ளன் (Young man)',
        'ளி (Food)',
        'ளை (Entertainment)',
        'ளோ (Wonder)'
      ],
      'ற': [
        'றவை (Assembly)',
        'றணம் (Crowd)',
        'றண்டு (Two)',
        'றல் (House)',
        'றை (Room)'
      ],
      'ன': [
        'னம் (Self)',
        'னி (Sweet)',
        'னவி (Dream)',
        'னைவு (Memory)',
        'னிமை (Solitude)'
      ],
    };

    // Add suggestions based on transliteration
    final translitBasedDict = {
      'a': [
        'அன்பு (Love)',
        'அறிவு (Knowledge)',
        'ஆடை (Dress)',
        'அமைதி (Peace)'
      ],
      'ā': [
        'ஆசை (Desire)',
        'ஆனந்தம் (Joy)',
        'ஆயுள் (Life)',
        'ஆரோக்கியம் (Health)'
      ],
      'i': [
        'இனிப்பு (Sweet)',
        'இலக்கு (Goal)',
        'இயற்கை (Nature)',
        'இளமை (Youth)'
      ],
      'ī': [
        'ஈகை (Charity)',
        'ஈடுபாடு (Involvement)',
        'ஈட்டம் (Wealth)',
        'ஈசன் (God)'
      ],
      'u': [
        'உறவு (Relationship)',
        'உழைப்பு (Labor)',
        'உணவு (Food)',
        'உரிமை (Right)'
      ],
      'e': [
        'எண்ணம் (Thought)',
        'எதிர்காலம் (Future)',
        'எளிமை (Simplicity)',
        'எழுச்சி (Rise)'
      ],
    };

    Set<String> suggestions = {};

    // Add suggestions for the base Tamil character
    if (tamilDictionary.containsKey(baseChar)) {
      suggestions.addAll(tamilDictionary[baseChar]!);
    }

    // Find similar characters for synonymic query expansion
    if (baseChar.isNotEmpty) {
      // For consonants, find other forms (Ka, Kā, Ki, etc.)
      for (String key in tamilDictionary.keys) {
        if (key != baseChar && key.startsWith(baseChar.substring(0, 1))) {
          // Add some words from related characters (limit to 2 for each related character)
          final relatedWords = tamilDictionary[key];
          if (relatedWords != null && relatedWords.isNotEmpty) {
            suggestions.addAll(relatedWords.take(2));
          }
        }
      }
    }

    // Add words based on transliteration search
    if (transliteration.isNotEmpty && transliteration.length > 0) {
      final translitFirstChar = transliteration.substring(0, 1).toLowerCase();
      if (translitBasedDict.containsKey(translitFirstChar)) {
        suggestions.addAll(translitBasedDict[translitFirstChar]!);
      }
    }

    return suggestions;
  }

  // Helper method to generate Arabic word suggestions
  static Set<String> _generateArabicSuggestions(
      String baseChar, String transliteration) {
    // Dictionary of Arabic words based on characters
    final Map<String, List<String>> arabicDictionary = {
      'ا': ['أب (Father)', 'أم (Mother)', 'أخ (Brother)', 'أخت (Sister)'],
      'ب': ['باب (Door)', 'بيت (House)', 'بحر (Sea)', 'بلد (Country)'],
      'ت': [
        'تفاحة (Apple)',
        'تمر (Dates)',
        'تلميذ (Student)',
        'تعليم (Education)'
      ],
      'ث': ['ثلاثة (Three)', 'ثعلب (Fox)', 'ثقافة (Culture)', 'ثوب (Dress)'],
      'ج': [
        'جميل (Beautiful)',
        'جبل (Mountain)',
        'جامعة (University)',
        'جديد (New)'
      ],
      'ح': ['حب (Love)', 'حياة (Life)', 'حديقة (Garden)', 'حلو (Sweet)'],
      'خ': [
        'خبز (Bread)',
        'خروف (Sheep)',
        'خريف (Autumn)',
        'خضار (Vegetables)'
      ],
      'د': ['دار (Home)', 'درس (Lesson)', 'دفتر (Notebook)', 'دجاج (Chicken)'],
      'ذ': ['ذهب (Gold)', 'ذئب (Wolf)', 'ذكي (Smart)', 'ذاكرة (Memory)'],
      'ر': ['رجل (Man)', 'رأس (Head)', 'رمل (Sand)', 'ربيع (Spring)'],
      'ز': ['زهرة (Flower)', 'زرافة (Giraffe)', 'زيت (Oil)', 'زبدة (Butter)'],
      'س': ['سماء (Sky)', 'سيارة (Car)', 'سمك (Fish)', 'سلام (Peace)'],
      'ش': ['شمس (Sun)', 'شجرة (Tree)', 'شتاء (Winter)', 'شاي (Tea)'],
      'ص': [
        'صديق (Friend)',
        'صباح (Morning)',
        'صيف (Summer)',
        'صورة (Picture)'
      ],
      'ض': ['ضوء (Light)', 'ضفدع (Frog)', 'ضيف (Guest)', 'ضحك (Laughter)'],
      'ط': ['طاولة (Table)', 'طريق (Road)', 'طالب (Student)', 'طبيب (Doctor)'],
      'ظ': ['ظهر (Back)', 'ظل (Shadow)', 'ظرف (Envelope)', 'ظلام (Darkness)'],
      'ع': ['عين (Eye)', 'عصفور (Bird)', 'عنب (Grapes)', 'عمل (Work)'],
      'غ': ['غرفة (Room)', 'غابة (Forest)', 'غداء (Lunch)', 'غريب (Strange)'],
      'ف': [
        'فم (Mouth)',
        'فيل (Elephant)',
        'فصل (Class/Chapter)',
        'فرح (Happiness)'
      ],
      'ق': ['قلب (Heart)', 'قمر (Moon)', 'قلم (Pen)', 'قطة (Cat)'],
      'ك': ['كتاب (Book)', 'كلب (Dog)', 'كرسي (Chair)', 'كبير (Big)'],
      'ل': ['ليل (Night)', 'لحم (Meat)', 'لون (Color)', 'لغة (Language)'],
      'م': ['ماء (Water)', 'مدرسة (School)', 'مطر (Rain)', 'مفتاح (Key)'],
      'ن': ['نار (Fire)', 'نهر (River)', 'نافذة (Window)', 'نجم (Star)'],
      'ه': ['هاتف (Phone)', 'هدية (Gift)', 'هواء (Air)', 'هلال (Crescent)'],
      'و': ['وجه (Face)', 'وردة (Rose)', 'ولد (Boy)', 'وقت (Time)'],
      'ي': ['يد (Hand)', 'يوم (Day)', 'ياسمين (Jasmine)', 'يمين (Right)'],
    };

    Set<String> suggestions = {};

    // Add suggestions for the base Arabic character
    if (arabicDictionary.containsKey(baseChar)) {
      suggestions.addAll(arabicDictionary[baseChar]!);
    }

    // Add some common Arabic phrases
    if (suggestions.isEmpty) {
      suggestions.addAll([
        'مرحبا (Hello)',
        'شكرا (Thank you)',
        'من فضلك (Please)',
        'أهلا وسهلا (Welcome)'
      ]);
    }

    return suggestions;
  }

  // Helper method to generate English word suggestions
  static Set<String> _generateEnglishSuggestions(String character) {
    // Dictionary for English letters
    final Map<String, List<String>> englishDictionary = {
      'A': ['Apple', 'Angel', 'Art', 'Amazing', 'Awesome'],
      'B': ['Book', 'Ball', 'Bird', 'Box', 'Beautiful'],
      'C': ['Cat', 'Car', 'Cake', 'Camera', 'Cool'],
      'D': ['Dog', 'Dance', 'Desk', 'Diamond', 'Dream'],
      'E': ['Earth', 'Eagle', 'Elephant', 'Energy', 'Easy'],
      'F': ['Fish', 'Flower', 'Friend', 'Food', 'Fun'],
      'G': ['Game', 'Garden', 'Girl', 'Green', 'Great'],
      'H': ['Hat', 'House', 'Heart', 'Horse', 'Happy'],
      'I': ['Ice', 'Island', 'Insect', 'Iron', 'Idea'],
      'J': ['Jump', 'Juice', 'Job', 'Jelly', 'Joy'],
      'K': ['Key', 'Kite', 'King', 'Kid', 'Kitchen'],
      'L': ['Lion', 'Lamp', 'Leaf', 'Love', 'Light'],
      'M': ['Moon', 'Music', 'Mountain', 'Mouse', 'Magic'],
      'N': ['Night', 'Name', 'Nature', 'Nose', 'New'],
      'O': ['Ocean', 'Orange', 'Owl', 'Office', 'Open'],
      'P': ['Pizza', 'Park', 'Pencil', 'Phone', 'Play'],
      'Q': ['Queen', 'Quick', 'Quiet', 'Question', 'Quality'],
      'R': ['River', 'Rain', 'Rainbow', 'Road', 'Run'],
      'S': ['Sun', 'Star', 'School', 'Sea', 'Smile'],
      'T': ['Tree', 'Train', 'Time', 'Tiger', 'Talk'],
      'U': ['Umbrella', 'Universe', 'Up', 'Uniform', 'Use'],
      'V': ['Voice', 'Video', 'Volcano', 'Vacation', 'Victory'],
      'W': ['Water', 'Wind', 'World', 'Watch', 'Window'],
      'X': ['X-ray', 'Xylophone', 'Box', 'Six', 'Fox'],
      'Y': ['Yellow', 'Year', 'Yoga', 'Yard', 'Young'],
      'Z': ['Zoo', 'Zebra', 'Zero', 'Zoom', 'Zigzag'],
      // Lowercase letters (simplified, add more as needed)
      'a': ['apple', 'art', 'amazing', 'air', 'animal'],
      'b': ['book', 'ball', 'beach', 'blue', 'birthday'],
      'c': ['cat', 'car', 'cake', 'color', 'cloud'],
      'd': ['dog', 'day', 'door', 'desk', 'dream'],
      'e': ['egg', 'eye', 'eat', 'evening', 'east'],
      'f': ['food', 'fun', 'friend', 'family', 'fast'],
      'g': ['good', 'game', 'girl', 'green', 'go'],
      'h': ['happy', 'house', 'hand', 'hat', 'help'],
      'i': ['ice', 'in', 'idea', 'if', 'important'],
      'j': ['jump', 'job', 'joy', 'juice', 'join'],
      'k': ['kind', 'key', 'know', 'kid', 'keep'],
      'l': ['love', 'light', 'learn', 'little', 'life'],
      'm': ['make', 'my', 'more', 'music', 'may'],
      'n': ['new', 'nice', 'not', 'now', 'name'],
      'o': ['open', 'one', 'of', 'on', 'over'],
      'p': ['play', 'put', 'part', 'place', 'people'],
      'q': ['quick', 'quiet', 'question', 'quite', 'quality'],
      'r': ['run', 'red', 'room', 'right', 'read'],
      's': ['see', 'say', 'so', 'small', 'school'],
      't': ['take', 'time', 'talk', 'to', 'the'],
      'u': ['use', 'up', 'us', 'under', 'until'],
      'v': ['very', 'view', 'voice', 'visit', 'video'],
      'w': ['walk', 'want', 'water', 'with', 'way'],
      'x': ['extra', 'x-ray', 'xmas', 'xenon', 'xenophobia'],
      'y': ['yes', 'you', 'your', 'yellow', 'yesterday'],
      'z': ['zebra', 'zero', 'zone', 'zoo', 'zinc'],
    };

    for (int i = 0; i <= 9; i++) {
      englishDictionary['$i'] = [
        'Number $i',
        '${i}th place',
        '$i items',
        '$i o\'clock'
      ];
    }

    // Special symbols
    englishDictionary['@'] = ['Email', 'At sign', 'Online', 'Internet'];
    englishDictionary['#'] = ['Hashtag', 'Number sign', 'Pound', 'Sharp'];
    englishDictionary['\$'] = ['Dollar', 'Money', 'Currency', 'Price'];

    Set<String> suggestions = {};

    // Add suggestions for English character
    if (englishDictionary.containsKey(character)) {
      suggestions.addAll(englishDictionary[character]!);
    } else {
      // If no direct match, add some common English words
      suggestions
          .addAll(['Hello', 'World', 'Good', 'Day', 'Friend', 'Welcome']);
    }

    return suggestions;
  }
}
