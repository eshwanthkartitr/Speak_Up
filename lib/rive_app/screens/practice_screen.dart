import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({Key? key}) : super(key: key);

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> with SingleTickerProviderStateMixin {
  bool _isPracticing = false;
  int _sessionDuration = 60; // seconds
  int _remainingTime = 0;
  Timer? _timer;
  Timer? _detectionTimer;
  int _currentSignIndex = 0;
  int _score = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Camera controller
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  
  // Simulated detection state
  double _signAccuracy = 0.0;
  String _feedbackMessage = "Position your hands in the frame";
  bool _isProcessing = false;
  final Random _random = Random();
  
  // Signs with predefined success rates
  final List<Map<String, dynamic>> _practiceSigns = [
    {
      "sign": "Hello",
      "difficulty": "Easy",
      "points": 5,
      "successRate": 0.9, // Very likely to succeed
      "feedbacks": [
        "Great! Hand raised at perfect height",
        "Move your hand slightly higher",
        "Wave your hand more naturally"
      ]
    },
    {
      "sign": "Thank You",
      "difficulty": "Easy",
      "points": 5,
      "successRate": 0.85,
      "feedbacks": [
        "Perfect! Hand touching chest",
        "Move your hand closer to your chest",
        "Keep your fingers together"
      ]
    },
    {
      "sign": "Please",
      "difficulty": "Medium",
      "points": 10,
      "successRate": 0.7,
      "feedbacks": [
        "Good circular motion!",
        "Make a circular motion on your chest",
        "Keep your palm flat against your chest"
      ]
    },
    {
      "sign": "Water",
      "difficulty": "Medium",
      "points": 10,
      "successRate": 0.6,
      "feedbacks": [
        "Perfect W hand shape!",
        "Form a W shape with your fingers",
        "Tap your fingers together like water"
      ]
    },
    {
      "sign": "Food",
      "difficulty": "Hard",
      "points": 15,
      "successRate": 0.5,
      "feedbacks": [
        "Great! Fingers to mouth motion",
        "Bring your fingers to your mouth",
        "Group your fingers together more"
      ]
    }
  ];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut)
    );
    
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras!.first,
        );

        _cameraController = CameraController(
          frontCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startPractice() {
    setState(() {
      _isPracticing = true;
      _remainingTime = _sessionDuration;
      _currentSignIndex = 0;
      _score = 0;
      _signAccuracy = 0.0;
      _feedbackMessage = "Position your hands in the frame";
    });

    _animationController.forward();
    _startDetectionSimulation();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
          if (_remainingTime < 10) {
            _animationController.reset();
            _animationController.forward();
          }
        } else {
          _nextSign();
        }
      });
    });
  }

  void _startDetectionSimulation() {
    _detectionTimer?.cancel();
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isPracticing) return;
      
      final currentSign = _practiceSigns[_currentSignIndex];
      final baseSuccessRate = currentSign["successRate"] as double;
      
      // Add some randomness to make it look more realistic
      final randomFactor = _random.nextDouble() * 0.3;
      final successRate = baseSuccessRate - randomFactor;
      
      // Simulate accuracy fluctuations
      setState(() {
        _signAccuracy = successRate;
        
        // Choose appropriate feedback based on accuracy
        final feedbacks = currentSign["feedbacks"] as List<String>;
        if (successRate > 0.8) {
          _feedbackMessage = feedbacks[0]; // Perfect
        } else if (successRate > 0.5) {
          _feedbackMessage = feedbacks[1]; // Good
        } else {
          _feedbackMessage = feedbacks[2]; // Needs improvement
        }
      });
    });
  }

  void _stopPractice() {
    _timer?.cancel();
    _detectionTimer?.cancel();
    _animationController.stop();
    
    setState(() {
      _isPracticing = false;
    });
  }

  void _nextSign() {
    final basePoints = _practiceSigns[_currentSignIndex]["points"] as int;
    final accuracyBonus = (_signAccuracy * basePoints).round();
    
    setState(() {
      _score += accuracyBonus;
      
      if (_currentSignIndex < _practiceSigns.length - 1) {
        _currentSignIndex++;
        _remainingTime = _sessionDuration;
        _signAccuracy = 0.0;
        _feedbackMessage = "Position your hands in the frame";
      } else {
        _stopPractice();
        _showCompletionDialog();
      }
    });
  }

  void _flipCamera() async {
    if (_cameras == null || _cameras!.length < 2 || _cameraController == null) return;
    
    // Get current camera position
    final currentDirection = _cameraController!.description.lensDirection;
    // Get the index of the next camera
    CameraDescription? newCamera;
    
    for (var camera in _cameras!) {
      if (camera.lensDirection != currentDirection) {
        newCamera = camera;
        break;
      }
    }
    
    if (newCamera == null) return;
    
    // Dispose current controller
    await _cameraController!.dispose();
    
    // Create new controller with the next camera
    _cameraController = CameraController(
      newCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    
    try {
      await _cameraController!.initialize();
      setState(() {});
    } catch (e) {
      debugPrint('Error flipping camera: $e');
    }
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy > 0.8) return Colors.green;
    if (accuracy > 0.6) return Colors.orange;
    if (accuracy > 0.4) return Colors.amber;
    return Colors.red;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _detectionTimer?.cancel();
    _animationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get available safe area to avoid overlapping with system UI
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;
    
    // Get theme provider to access dark mode state
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Container(
      color: RiveAppTheme.getBackgroundColor(isDarkMode),
      child: Column(
        children: [
          // Increased top padding to avoid conflicts with menu button
          SizedBox(height: safePadding.top + 60),
          
          // Custom App Bar with proper spacing
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title centered without interference from menu button
                Expanded(
                  child: Center(
                    child: Text(
                      'Sign Practice',
                      style: TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold,
                        color: RiveAppTheme.getTextColor(isDarkMode),
                      ),
                    ),
                  ),
                ),
                // Help button positioned far right to avoid overlap
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: RiveAppTheme.getCardColor(isDarkMode),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: RiveAppTheme.accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Main content with more space for bottom navigation
          Expanded(
            child: _isPracticing 
                ? _buildPracticeView(isDarkMode)
                : _buildPracticeSetupView(isDarkMode),
          ),
          
          // Increased bottom padding for tab bar
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPracticeSetupView(bool isDarkMode) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // Reduced top padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Practice intro card - simplified design
            Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    RiveAppTheme.accentColor.withOpacity(0.7),
                    RiveAppTheme.accentColor.withOpacity(0.4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: RiveAppTheme.accentColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.sign_language,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Text(
                          'Daily Practice',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Practice your sign language skills with timed sessions',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            // Practice settings card - cleaner layout
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: RiveAppTheme.getCardColor(isDarkMode),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: RiveAppTheme.getTextColor(isDarkMode),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Session Duration:',
                          style: TextStyle(
                            color: RiveAppTheme.getTextColor(isDarkMode),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: RiveAppTheme.getInputBackgroundColor(isDarkMode),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<int>(
                            value: _sessionDuration,
                            underline: const SizedBox(),
                            isDense: true,
                            dropdownColor: RiveAppTheme.getCardColor(isDarkMode),
                            items: [30, 45, 60, 90].map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(
                                  '$value sec',
                                  style: TextStyle(
                                    color: RiveAppTheme.getTextColor(isDarkMode),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (int? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _sessionDuration = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Signs to Practice:',
                          style: TextStyle(
                            color: RiveAppTheme.getTextColor(isDarkMode),
                          ),
                        ),
                        Text(
                          '${_practiceSigns.length} signs',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: RiveAppTheme.getTextColor(isDarkMode),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Start button - more streamlined
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 3,
                backgroundColor: RiveAppTheme.accentColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadowColor: RiveAppTheme.accentColor.withOpacity(0.4),
              ),
              onPressed: _startPractice,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.play_arrow, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Start Practice',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Practice tips - simplified
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? Colors.orange.withOpacity(0.15)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode 
                      ? Colors.orange.withOpacity(0.4)
                      : Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline, 
                    color: isDarkMode ? Colors.orange[300] : Colors.orange,
                    size: 18
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Position yourself in a well-lit area for better sign recognition',
                      style: TextStyle(
                        color: isDarkMode 
                            ? Colors.white.withOpacity(0.9)
                            : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeView(bool isDarkMode) {
    final currentSign = _practiceSigns[_currentSignIndex];
    final difficultyColor = currentSign["difficulty"] == "Easy" 
        ? Colors.green 
        : currentSign["difficulty"] == "Medium" 
            ? Colors.orange 
            : Colors.red;

    return Column(
      children: [
        // Progress indicator - with better scaling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Sign ${_currentSignIndex + 1}/${_practiceSigns.length}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: RiveAppTheme.getTextColor(isDarkMode),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (_currentSignIndex + 1) / _practiceSigns.length,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: RiveAppTheme.accentColor,
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RiveAppTheme.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Text(
                      '$_score',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: RiveAppTheme.getTextColor(isDarkMode),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Timer display - more compact
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _remainingTime < 10 ? _animation.value : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
                decoration: BoxDecoration(
                  color: _remainingTime > 10 
                      ? RiveAppTheme.accentColor.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _remainingTime > 10 
                        ? RiveAppTheme.accentColor.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  '$_remainingTime',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _remainingTime > 10 
                        ? RiveAppTheme.accentColor
                        : Colors.red,
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        // Sign to practice card - better proportions
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Card(
            elevation: 3,
            color: RiveAppTheme.getCardColor(isDarkMode),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Practice Sign:',
                        style: TextStyle(
                          fontSize: 14, 
                          color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, 
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: difficultyColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: difficultyColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 12,
                              color: difficultyColor,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              currentSign["difficulty"],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: difficultyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currentSign["sign"],
                    style: TextStyle(
                      fontSize: 30, 
                      fontWeight: FontWeight.bold,
                      color: RiveAppTheme.getTextColor(isDarkMode),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${currentSign["points"]} points',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Camera feed with accuracy feedback
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode 
                    ? Colors.white.withOpacity(0.1)
                    : RiveAppTheme.getDividerColor(isDarkMode),
              ),
              color: isDarkMode ? Colors.black.withOpacity(0.3) : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  // Camera feed
                  _isCameraInitialized
                      ? AspectRatio(
                          aspectRatio: _cameraController!.value.aspectRatio,
                          child: CameraPreview(_cameraController!),
                        )
                      : Center(
                          child: Text(
                            'Initializing camera...',
                            style: TextStyle(
                              color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                            ),
                          ),
                        ),
                
                  // Accuracy indicator with better dark mode visibility
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        // Accuracy progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: _signAccuracy,
                            backgroundColor: isDarkMode 
                                ? Colors.black.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.3),
                            color: _getAccuracyColor(_signAccuracy),
                            minHeight: 10,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Feedback message with better visibility
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDarkMode 
                                ? Colors.black.withOpacity(0.7)
                                : Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDarkMode 
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            _feedbackMessage,
                            style: TextStyle(
                              color: isDarkMode 
                                  ? Colors.white
                                  : Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                  // Hand guide overlay with better visibility
                  Center(
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _getAccuracyColor(_signAccuracy).withOpacity(isDarkMode ? 0.7 : 0.5),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(90),
                      ),
                    ),
                  ),
                
                  // Camera controls with better dark mode
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                            ? Colors.black.withOpacity(0.7)
                            : RiveAppTheme.getCardColor(isDarkMode).withOpacity(0.8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDarkMode 
                              ? Colors.white.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                      ),
                      child: InkWell(
                        onTap: _flipCamera,
                        child: Icon(
                          Icons.flip_camera_ios,
                          color: isDarkMode ? Colors.white : RiveAppTheme.getTextColor(isDarkMode),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Controls row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                    foregroundColor: RiveAppTheme.getTextColor(isDarkMode),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _stopPractice,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Next Sign'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RiveAppTheme.accentColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _nextSign,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCompletionDialog() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDarkMode ? RiveAppTheme.cardDark : RiveAppTheme.cardLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            Text(
              'Practice Complete',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Great job! You\'ve practiced all the signs.',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
              decoration: BoxDecoration(
                color: RiveAppTheme.accentColor.withOpacity(isDarkMode ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Total Score: ',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  Text(
                    '$_score points',
                    style: TextStyle(
                      color: RiveAppTheme.accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Close',
              style: TextStyle(
                color: isDarkMode ? Colors.white60 : Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RiveAppTheme.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _startPractice();
            },
            child: const Text('Practice Again'),
          ),
        ],
      ),
    );
  }
}