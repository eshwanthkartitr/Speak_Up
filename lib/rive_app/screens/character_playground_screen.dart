import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_samples/rive_app/utils/model_helper.dart';
import 'package:image/image.dart' as img;

class CharacterPlaygroundScreen extends StatefulWidget {
  const CharacterPlaygroundScreen({Key? key}) : super(key: key);

  @override
  State<CharacterPlaygroundScreen> createState() => _CharacterPlaygroundScreenState();
}

class _CharacterPlaygroundScreenState extends State<CharacterPlaygroundScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  String? _currentPrediction;
  double? _currentConfidence;
  String _currentSentence = '';
  List<String> _wordSuggestions = [];
  bool _isProcessing = false;
  final List<String> _detectedCharacters = [];
  final Duration _processingDelay = const Duration(milliseconds: 500);
  Timer? _processingTimer;
  List<String>? _labels;
  bool _modelInitialized = false;
  String _characterType = "Tamil"; // Default character set
  
  // Toggle options for character sets
  final List<String> _characterSets = ["Tamil", "Arabic", "English"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeModel();
    _initializeCamera();
  }

  Future<void> _initializeModel() async {
    try {
      // Load labels
      _labels = await ModelHelper.loadLabels('assets/models/labels.txt');
      
      // Copy model file to documents directory
      await ModelHelper.copyModelToDocuments('assets/models/mobilenetv3_best.pth', 'mobilenetv3_best.pth');
      
      setState(() {
        _modelInitialized = true;
      });
      
      print('Model initialized successfully');
    } catch (e) {
      print('Error initializing model: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _processingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    // Use front camera for character detection
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
        _startProcessing();
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  void _stopCamera() {
    _controller?.dispose();
    _controller = null;
    _processingTimer?.cancel();
    _processingTimer = null;
    
    if (mounted) {
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  void _startProcessing() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Set up a timer to process frames every 0.5 seconds
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(_processingDelay, (timer) {
      if (!_isProcessing) {
        _processFrame();
      }
    });
    
    // Start camera stream
    _controller!.startImageStream((image) {
      // Do nothing here, we'll process frames on a timer
    });
  }

  Future<void> _processFrame() async {
    if (_isProcessing || _controller == null || !_controller!.value.isInitialized) return;
    
    _isProcessing = true;
    
    try {
      // Temporarily stop the stream to take a picture
      await _controller!.stopImageStream();
      
      // Take a picture
      final XFile picture = await _controller!.takePicture();
      
      // Process the image
      final imageBytes = await picture.readAsBytes();
      final processedImage = img.decodeImage(imageBytes);
      
      // Get prediction based on character type
      if (processedImage != null) {
        final prediction = ModelHelper.simulatePrediction(
          processedImage, 
          characterSet: _characterType
        );
        final confidence = 0.7 + math.Random().nextDouble() * 0.3; // Simulate confidence
        
        if (prediction.isNotEmpty && mounted) {
          setState(() {
            _currentPrediction = prediction;
            _currentConfidence = confidence;
            _wordSuggestions = ModelHelper.generateWordSuggestions(
              prediction,
              characterSet: _characterType,
            );
          });
        }
      }
      
      // Restart the stream
      if (mounted) {
        _controller!.startImageStream((image) {
          // We're processing frames on a timer, not in the stream callback
        });
      }
    } catch (e) {
      print('Error processing frame: $e');
      
      // Make sure to restart the stream even if there's an error
      if (mounted && _controller != null && _controller!.value.isInitialized) {
        _controller!.startImageStream((image) {});
      }
    } finally {
      _isProcessing = false;
    }
  }
  
  void _addCharacterToSentence() {
    if (_currentPrediction != null) {
      setState(() {
        // Extract just the character without the transliteration
        final character = _extractCharacterWithoutTransliteration(_currentPrediction!);
        _detectedCharacters.add(character);
        _currentSentence = _detectedCharacters.join('');
      });
    }
  }
  
  String _extractCharacterWithoutTransliteration(String input) {
    // Extract just the character part (before the parenthesis)
    final match = RegExp(r'^([^\(]+)').firstMatch(input);
    if (match != null) {
      return match.group(1)!;
    }
    return input;
  }
  
  void _addWordToSentence(String word) {
    setState(() {
      if (_currentSentence.isNotEmpty && !_currentSentence.endsWith(' ')) {
        _currentSentence += ' ';
      }
      // Extract just the word without the translation in parentheses
      final extractedWord = _extractWordWithoutTranslation(word);
      _currentSentence += '$extractedWord ';
      _detectedCharacters.clear(); // Clear individual characters after adding a word
    });
  }
  
  String _extractWordWithoutTranslation(String input) {
    // Extract the word part (before the parenthesis)
    final match = RegExp(r'^([^\(]+)').firstMatch(input);
    if (match != null) {
      return match.group(1)!.trim();
    }
    return input;
  }
  
  void _clearSentence() {
    setState(() {
      _currentSentence = '';
      _detectedCharacters.clear();
    });
  }

  void _changeCharacterSet(String newSet) {
    setState(() {
      _characterType = newSet;
      // Reset current prediction when changing character set
      _currentPrediction = null;
      _wordSuggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: RiveAppTheme.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: RiveAppTheme.getTextColor(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Character Playground',
          style: TextStyle(
            color: RiveAppTheme.getTextColor(isDarkMode),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Character set selector
          PopupMenuButton<String>(
            icon: Icon(
              Icons.language,
              color: RiveAppTheme.getTextColor(isDarkMode),
            ),
            tooltip: 'Select character set',
            onSelected: _changeCharacterSet,
            itemBuilder: (context) {
              return _characterSets.map((String set) {
                return PopupMenuItem<String>(
                  value: set,
                  child: Row(
                    children: [
                      Icon(
                        _characterType == set ? Icons.check : null,
                        color: RiveAppTheme.accentColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(set),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Current sentence display
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? RiveAppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Sentence:',
                      style: TextStyle(
                        color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _characterType,
                          style: TextStyle(
                            color: RiveAppTheme.accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                            size: 18,
                          ),
                          onPressed: _clearSentence,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _currentSentence.isEmpty ? 'No text yet' : _currentSentence,
                  style: TextStyle(
                    color: RiveAppTheme.getTextColor(isDarkMode),
                    fontSize: 20, // Increased font size for better readability
                    fontWeight: FontWeight.w500,
                    fontFamily: 'NotoSansTamil', // Use appropriate font for Tamil
                  ),
                ),
              ],
            ),
          ),
          
          // Camera preview
          Expanded(
            flex: 3,
            child: _isCameraInitialized
                ? _buildCameraPreview()
                : const Center(child: CircularProgressIndicator()),
          ),
          
          // Prediction and word suggestions
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? RiveAppTheme.cardDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detected Character:',
                              style: TextStyle(
                                color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _currentPrediction ?? '--',
                                    style: TextStyle(
                                      color: RiveAppTheme.getTextColor(isDarkMode),
                                      fontSize: 28, // Increased font size for better visibility
                                      fontWeight: FontWeight.bold,
                                      fontFamily: _characterType == 'Tamil' 
                                          ? 'NotoSansTamil' 
                                          : (_characterType == 'Arabic' ? 'NotoNaskhArabic' : 'Roboto'),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (_currentConfidence != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getConfidenceColor(_currentConfidence!).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${(_currentConfidence! * 100).toInt()}%',
                                      style: TextStyle(
                                        color: _getConfidenceColor(_currentConfidence!),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _currentPrediction != null ? _addCharacterToSentence : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RiveAppTheme.accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Word Suggestions:',
                    style: TextStyle(
                      color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _wordSuggestions.isEmpty
                        ? Center(
                            child: Text(
                              'No suggestions available',
                              style: TextStyle(
                                color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _wordSuggestions.length,
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: () => _addWordToSentence(_wordSuggestions[index]),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDarkMode 
                                        ? Colors.grey.shade800 
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: RiveAppTheme.accentColor.withOpacity(0.3),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _wordSuggestions[index],
                                    style: TextStyle(
                                      color: RiveAppTheme.getTextColor(isDarkMode),
                                      fontWeight: FontWeight.w500,
                                      fontFamily: _characterType == 'Tamil' 
                                          ? 'NotoSansTamil' 
                                          : (_characterType == 'Arabic' ? 'NotoNaskhArabic' : 'Roboto'),
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Stack(
            children: [
              CameraPreview(_controller!),
              // Processing indicator
              if (_isProcessing)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: RiveAppTheme.accentColor.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _characterType,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Scanning every 0.5s',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Model initialization status
              if (!_modelInitialized)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Initializing model...',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return Colors.green;
    if (confidence >= 0.7) return Colors.blue;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }
} 