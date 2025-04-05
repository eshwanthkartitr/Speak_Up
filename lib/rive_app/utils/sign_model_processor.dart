import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class SignModelProcessor {
  // Singleton pattern
  static final SignModelProcessor _instance = SignModelProcessor._internal();
  factory SignModelProcessor() => _instance;

  Interpreter? _mobilenetV3Interpreter;
  List<String>? _labels;
  bool _isInitialized = false;
  Timer? _processingTimer;
  String? _lastPrediction;
  double? _confidence;
  
  // Callback for predictions
  Function(String prediction, double confidence)? onPrediction;
  
  SignModelProcessor._internal();
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load labels
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n')
          .where((label) => label.trim().isNotEmpty)
          .toList();
      
      // Copy model from assets to a location where it can be loaded from
      final appDir = await getApplicationDocumentsDirectory();
      final modelPath = '${appDir.path}/mobilenetv3_best.pth';
      
      // Check if model exists, if not, copy it
      final modelFile = File(modelPath);
      if (!modelFile.existsSync()) {
        final ByteData data = await rootBundle.load('assets/models/mobilenetv3_best.pth');
        final Uint8List bytes = data.buffer.asUint8List();
        await modelFile.writeAsBytes(bytes);
      }
      
      // Load interpreter (Note: TFLite Flutter doesn't directly support PyTorch models,
      // but for the purpose of this demonstration, we're simplifying the implementation)
      // In a real application, you would need to convert PyTorch models to TFLite format
      // or use a different approach to load PyTorch models in Flutter
      _mobilenetV3Interpreter = await Interpreter.fromAsset('assets/models/mobilenetv3_best.tflite');
      
      _isInitialized = true;
      print('SignModelProcessor initialized successfully');
    } catch (e) {
      print('Error initializing SignModelProcessor: $e');
    }
  }
  
  void startProcessingStream(CameraController controller, {Duration interval = const Duration(milliseconds: 500)}) {
    if (!_isInitialized) {
      print('SignModelProcessor not initialized. Call initialize() first.');
      return;
    }
    
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(interval, (timer) {
      if (controller.value.isInitialized && !controller.value.isStreamingImages) {
        _processFrame(controller);
      }
    });
  }
  
  void stopProcessing() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }
  
  Future<void> _processFrame(CameraController controller) async {
    if (!_isInitialized || _mobilenetV3Interpreter == null) return;
    
    try {
      final image = await controller.takePicture();
      final imageBytes = await File(image.path).readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);
      
      if (decodedImage == null) return;
      
      // Resize and preprocess the image
      final processedImage = img.copyResize(
        decodedImage,
        width: 224,
        height: 224,
      );
      
      // Convert to input tensor format (float32 array normalized to [0, 1])
      final inputBuffer = _imageToFloatBuffer(processedImage);
      
      // Create output buffer for results
      final outputBuffer = List.filled(94, 0.0).reshape([1, 94]); // 94 classes in labels.txt
      
      // Run inference
      _mobilenetV3Interpreter!.run(inputBuffer, outputBuffer);
      
      // Find the class with highest probability
      final resultList = outputBuffer[0] as List<double>;
      int maxIndex = 0;
      double maxValue = resultList[0];
      
      for (int i = 1; i < resultList.length; i++) {
        if (resultList[i] > maxValue) {
          maxValue = resultList[i];
          maxIndex = i;
        }
      }
      
      if (maxIndex < _labels!.length) {
        final prediction = _labels![maxIndex];
        _lastPrediction = prediction;
        _confidence = maxValue;
        
        // Notify listeners with the prediction
        onPrediction?.call(prediction, maxValue);
      }
      
      // Delete the temporary image file
      await File(image.path).delete();
      
    } catch (e) {
      print('Error processing frame: $e');
    }
  }
  
  List<List<List<List<double>>>> _imageToFloatBuffer(img.Image image) {
    const int channels = 3; // RGB
    final inputShape = [1, 224, 224, channels]; // batch size, height, width, channels
    
    // Initialize a 4D tensor with shape [1, 224, 224, 3]
    final List<List<List<List<double>>>> inputBuffer = List.generate(
      1, // batch size
      (_) => List.generate(
        224, // height
        (_) => List.generate(
          224, // width
          (_) => List.generate(
            channels, // channels
            (_) => 0.0,
          ),
        ),
      ),
    );
    
    // Fill the buffer with normalized pixel values
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        
        // Normalize to [0, 1]
        inputBuffer[0][y][x][0] = img.getRed(pixel) / 255.0;
        inputBuffer[0][y][x][1] = img.getGreen(pixel) / 255.0;
        inputBuffer[0][y][x][2] = img.getBlue(pixel) / 255.0;
      }
    }
    
    return inputBuffer;
  }
  
  // Generate word suggestions based on the predicted character
  List<String> generateWordSuggestions(String character) {
    final suggestions = <String>[];
    
    // Basic dictionary for demonstration purposes
    // In a real app, you'd want to use a more comprehensive dictionary
    final Map<String, List<String>> wordDictionary = {
      'A': ['Apple', 'Angel', 'Ant', 'Arrow', 'Awesome'],
      'B': ['Book', 'Ball', 'Banana', 'Bird', 'Boat'],
      'C': ['Cat', 'Car', 'Cake', 'Cup', 'Camera'],
      'D': ['Dog', 'Door', 'Desk', 'Duck', 'Diamond'],
      'E': ['Egg', 'Elephant', 'Eagle', 'Earth', 'Eye'],
      'F': ['Fish', 'Flower', 'Flag', 'Food', 'Friend'],
      'G': ['Game', 'Garden', 'Girl', 'Glass', 'Green'],
      'H': ['Hat', 'House', 'Hand', 'Horse', 'Heart'],
      'I': ['Ice', 'Island', 'Ink', 'Insect', 'Iron'],
      'J': ['Juice', 'Jacket', 'Jam', 'Jump', 'Jungle'],
      'K': ['Key', 'King', 'Kite', 'Kitchen', 'Kitten'],
      'L': ['Lion', 'Lamp', 'Leaf', 'Leg', 'Letter'],
      'M': ['Mouse', 'Moon', 'Mountain', 'Milk', 'Map'],
      'N': ['Nose', 'Nest', 'Nut', 'Night', 'Notebook'],
      'O': ['Orange', 'Ocean', 'Oil', 'Owl', 'Office'],
      'P': ['Pen', 'Paper', 'Plane', 'Park', 'Phone'],
      'Q': ['Queen', 'Question', 'Quiet', 'Quick', 'Quarter'],
      'R': ['Rain', 'Rose', 'Rabbit', 'Radio', 'Ring'],
      'S': ['Sun', 'Star', 'Song', 'Snake', 'School'],
      'T': ['Tree', 'Table', 'Train', 'Tiger', 'Time'],
      'U': ['Umbrella', 'Uncle', 'Under', 'Up', 'Use'],
      'V': ['Van', 'Voice', 'Video', 'Violet', 'Vacation'],
      'W': ['Water', 'Window', 'Watch', 'Wood', 'Wolf'],
      'X': ['X-ray', 'Xylophone', 'Box', 'Six', 'Fox'],
      'Y': ['Yellow', 'Yard', 'Yogurt', 'Yolk', 'Year'],
      'Z': ['Zoo', 'Zebra', 'Zipper', 'Zero', 'Zone'],
    };
    
    if (wordDictionary.containsKey(character)) {
      return wordDictionary[character]!;
    }
    
    return suggestions;
  }
  
  void dispose() {
    stopProcessing();
    _mobilenetV3Interpreter?.close();
    _isInitialized = false;
  }
} 