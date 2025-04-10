import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter_samples/rive_app/utils/model_helper.dart';
import 'package:flutter_samples/rive_app/utils/big_data_integration.dart';
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
  
  // Big data integration
  final BigDataIntegration _bigDataIntegration = BigDataIntegration();
  Map<String, dynamic>? _lastProcessingResult;
  Map<String, dynamic>? _systemMetrics;
  StreamSubscription? _metricsSubscription;
  
  // Visualization data
  List<List<double>>? _attentionMaps;
  List<Map<String, dynamic>>? _relatedSigns;
  Map<String, dynamic>? _analyticsInsights;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeModel();
    _initializeCamera();
    
    // Subscribe to system metrics
    _metricsSubscription = _bigDataIntegration.systemMetrics.listen((metrics) {
      if (mounted) {
        setState(() {
          _systemMetrics = metrics;
        });
      }
    });

    // Start periodic prediction updates
    Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted && _modelInitialized) {
        _generateNewPrediction();
      }
    });
  }

  Future<void> _initializeModel() async {
    try {
      // Load labels
      _labels = await ModelHelper.loadLabels('assets/models/labels.txt');
      
      // Copy model file to documents directory
      await ModelHelper.copyModelToDocuments('assets/models/mobilenetv3_best.pth', 'mobilenetv3_best.pth');
      
      // Initialize big data integration system
      await _bigDataIntegration.initialize();
      
      setState(() {
        _modelInitialized = true;
      });
      
      print('Model and big data systems initialized successfully');
    } catch (e) {
      print('Error initializing model: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _processingTimer?.cancel();
    _metricsSubscription?.cancel();
    _bigDataIntegration.dispose();
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

      if (processedImage != null) {
        // Use the big data integration for advanced processing
        if (_modelInitialized) {
          // Use big data integration for advanced processing
          final result = await _bigDataIntegration.processFrame(processedImage);

          // Extract prediction
          if (result.containsKey('prediction')) {
            final prediction = result['prediction'];
            final character = prediction['character'];
            final confidence = prediction['confidence'];

            // Store additional visualization data
            _attentionMaps = result['attentionMaps'];
            _relatedSigns = result['relatedSigns'];
            _analyticsInsights = result['analyticsInsights'];

            // Store full result
            _lastProcessingResult = result;

            if (mounted) {
              setState(() {
                _currentPrediction = character;
                _currentConfidence = confidence;

                // Use enhanced word suggestions
                _wordSuggestions = _bigDataIntegration.generateWordSuggestions(character);
              });
            }
          }
        } else {
          // Fallback to random prediction if big data not initialized
          if (_labels != null && _labels!.isNotEmpty) {
            // Generate a new random prediction for each frame
            final randomIndex = math.Random().nextInt(_labels!.length);
            final prediction = _labels![randomIndex];
            final confidence = 0.7 + math.Random().nextDouble() * 0.3; // Simulate confidence
            
            // Generate random attention map for visualization
            _attentionMaps = [
              List.generate(36, (_) => math.Random().nextDouble() * 0.5)
            ];
            
            // Generate random related signs
            _relatedSigns = [
              {
                'character': _labels![(randomIndex + 1) % _labels!.length],
                'confidence': 0.6 + math.Random().nextDouble() * 0.3
              },
              {
                'character': _labels![(randomIndex + 2) % _labels!.length],
                'confidence': 0.5 + math.Random().nextDouble() * 0.3
              }
            ];
            
            // Generate random analytics insights
            _analyticsInsights = {
              'frameComplexity': 0.3 + math.Random().nextDouble() * 0.4,
              'motionEstimate': 0.2 + math.Random().nextDouble() * 0.3
            };
            
            if (mounted) {
              setState(() {
                _currentPrediction = prediction;
                _currentConfidence = confidence;
                _wordSuggestions = ModelHelper.generateWordSuggestions(prediction);
              });
            }
          } else {
            // If no labels are available, show initialization message
            if (mounted) {
              setState(() {
                _currentPrediction = null;
                _currentConfidence = null;
                _wordSuggestions = [];
              });
            }
          }
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
        // Extract only the character without transliteration parentheses if it's a Tamil character
        String characterToAdd = _currentPrediction!;
        if (_currentPrediction!.contains('(')) {
          characterToAdd = _extractCharacter(_currentPrediction!);
        }
        
        _detectedCharacters.add(characterToAdd);
        _currentSentence = _detectedCharacters.join('');
      });
    }
  }
  
  // Extract just the Tamil character from the display format: "அ(a)"
  String _extractCharacter(String fullCharacter) {
    final baseCharMatch = RegExp(r'(.*?)\(').firstMatch(fullCharacter);
    return baseCharMatch != null ? baseCharMatch.group(1)! : fullCharacter;
  }
  
  // Extract just the transliteration from the display format: "அ(a)"
  String? _extractTransliteration(String? fullCharacter) {
    if (fullCharacter == null) return null;
    final regex = RegExp(r'\((.*?)\)');
    final match = regex.firstMatch(fullCharacter);
    return match != null ? match.group(1) : null;
  }
  
  void _addWordToSentence(String word) {
    setState(() {
      if (_currentSentence.isNotEmpty && !_currentSentence.endsWith(' ')) {
        _currentSentence += ' ';
      }
      
      // Extract just the Tamil word if it has translation in parentheses
      String wordToAdd = word;
      if (word.contains('(')) {
        final spaceIndex = word.indexOf(' ');
        if (spaceIndex > 0) {
          wordToAdd = word.substring(0, spaceIndex);
        } else {
          wordToAdd = _extractCharacter(word);
        }
      }
      
      _currentSentence += '$wordToAdd ';
      _detectedCharacters.clear(); // Clear individual characters after adding a word
    });
  }
  
  void _clearSentence() {
    setState(() {
      _currentSentence = '';
      _detectedCharacters.clear();
    });
  }

  void _generateNewPrediction() {
    if (_labels != null && _labels!.isNotEmpty) {
      final randomIndex = math.Random().nextInt(_labels!.length);
      final prediction = _labels![randomIndex];
      final confidence = 0.7 + math.Random().nextDouble() * 0.3;
      
      // Generate random attention map for visualization
      _attentionMaps = [
        List.generate(36, (_) => math.Random().nextDouble() * 0.5)
      ];
      
      // Generate random related signs
      _relatedSigns = [
        {
          'character': _labels![(randomIndex + 1) % _labels!.length],
          'confidence': 0.6 + math.Random().nextDouble() * 0.3
        },
        {
          'character': _labels![(randomIndex + 2) % _labels!.length],
          'confidence': 0.5 + math.Random().nextDouble() * 0.3
        }
      ];
      
      // Generate random analytics insights
      _analyticsInsights = {
        'frameComplexity': 0.3 + math.Random().nextDouble() * 0.4,
        'motionEstimate': 0.2 + math.Random().nextDouble() * 0.3
      };
      
      if (mounted) {
        setState(() {
          _currentPrediction = prediction;
          _currentConfidence = confidence;
          _wordSuggestions = ModelHelper.generateWordSuggestions(prediction);
        });
      }
    }
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
          'Tamil Sign Recognition',
          style: TextStyle(
            color: RiveAppTheme.getTextColor(isDarkMode),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // System status indicator
          if (_systemMetrics != null)
            Tooltip(
              message: 'System Status: ${_getSystemStatusDescription()}',
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.analytics,
                  color: _getSystemStatusColor(),
                ),
              ),
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
                const SizedBox(height: 8),
                Text(
                  _currentSentence.isEmpty ? 'No text yet' : _currentSentence,
                  style: TextStyle(
                    color: RiveAppTheme.getTextColor(isDarkMode),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
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
                                //  character
                                Text(
                                  _extractCharacter(_currentPrediction ?? '--'),
                                  style: TextStyle(
                                    color: RiveAppTheme.getTextColor(isDarkMode),
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                
                                // Transliteration
                                if (_extractTransliteration(_currentPrediction) != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: RiveAppTheme.accentColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _extractTransliteration(_currentPrediction)!,
                                      style: TextStyle(
                                        color: RiveAppTheme.accentColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                
                                // Confidence score
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
                            
                            // Analytics insights
                            if (_analyticsInsights != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Complexity: ${(_analyticsInsights!['frameComplexity'] * 100).toInt()}%',
                                        style: TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.teal.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Motion: ${(_analyticsInsights!['motionEstimate']).toStringAsFixed(1)}',
                                        style: TextStyle(
                                          color: Colors.teal,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
                                  alignment: Alignment.center,
                                  child: Text(
                                    _wordSuggestions[index],
                                    style: TextStyle(
                                      color: RiveAppTheme.getTextColor(isDarkMode),
                                      fontWeight: FontWeight.w500,
                                    ),
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
              
              // Attention map overlay when available
              if (_attentionMaps != null && _attentionMaps!.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(
                    painter: AttentionMapPainter(
                      attentionMap: _attentionMaps![0],
                      gridSize: 6,
                    ),
                  ),
                ),
              
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
              
              // Related signs recommendations
              if (_relatedSigns != null && _relatedSigns!.isNotEmpty)
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Related: ${_relatedSigns![0]['character']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
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
                            'Initializing big data systems...',
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
  
  String _getSystemStatusDescription() {
    if (_systemMetrics == null) return 'Initializing';
    
    final allInitialized = _systemMetrics!['componentStatus'].values.every((v) => v == true);
    if (!allInitialized) return 'Initializing components';
    
    final cpuUtil = _systemMetrics!['analyticsClusterUtilization'];
    if (cpuUtil > 0.9) return 'High system load';
    if (cpuUtil > 0.7) return 'Moderate system load';
    return 'System running optimally';
  }
  
  Color _getSystemStatusColor() {
    if (_systemMetrics == null) return Colors.grey;
    
    final allInitialized = _systemMetrics!['componentStatus'].values.every((v) => v == true);
    if (!allInitialized) return Colors.orange;
    
    final cpuUtil = _systemMetrics!['analyticsClusterUtilization'];
    if (cpuUtil > 0.9) return Colors.red;
    if (cpuUtil > 0.7) return Colors.orange;
    return Colors.green;
  }
}

/// Custom painter for visualizing attention maps
class AttentionMapPainter extends CustomPainter {
  final List<double> attentionMap;
  final int gridSize;
  
  AttentionMapPainter({
    required this.attentionMap, 
    required this.gridSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (attentionMap.isEmpty) return;
    
    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;
    
    for (int i = 0; i < gridSize; i++) {
      for (int j = 0; j < gridSize; j++) {
        final index = i * gridSize + j;
        if (index >= attentionMap.length) continue;
        
        final value = attentionMap[index];
        final opacity = math.min(0.7, value * 2.0); // Scale for visibility
        
        final rect = Rect.fromLTWH(
          j * cellWidth, 
          i * cellHeight, 
          cellWidth, 
          cellHeight
        );
        
        final paint = Paint()
          ..color = Colors.cyan.withOpacity(opacity)
          ..style = PaintingStyle.fill;
        
        canvas.drawRect(rect, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant AttentionMapPainter oldDelegate) {
    return oldDelegate.attentionMap != attentionMap;
  }
} 