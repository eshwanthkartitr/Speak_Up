import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/theme.dart';

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
  int _currentSignIndex = 0;
  int _score = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // More interesting sign list with categories
  final List<Map<String, dynamic>> _practiceSigns = [
    {"sign": "Hello", "difficulty": "Easy", "points": 5},
    {"sign": "Thank You", "difficulty": "Easy", "points": 5},
    {"sign": "Please", "difficulty": "Easy", "points": 5},
    {"sign": "Sorry", "difficulty": "Medium", "points": 10},
    {"sign": "Help", "difficulty": "Medium", "points": 10},
    {"sign": "Friend", "difficulty": "Medium", "points": 10},
    {"sign": "Understand", "difficulty": "Hard", "points": 15},
    {"sign": "Remember", "difficulty": "Hard", "points": 15},
  ];

  @override
  void initState() {
    super.initState();
    
    // Setup animation for countdown timer
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    
    _animation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut)
    );
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
  }

  void _startPractice() {
    setState(() {
      _isPracticing = true;
      _remainingTime = _sessionDuration;
      _currentSignIndex = 0;
      _score = 0;
    });

    _animationController.forward();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
          // Pulse animation when time is low
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

  void _stopPractice() {
    _timer?.cancel();
    _animationController.stop();
    
    setState(() {
      _isPracticing = false;
    });
  }

  void _nextSign() {
    setState(() {
      // Add points for the current sign
      _score += _practiceSigns[_currentSignIndex]["points"] as int;
      
      if (_currentSignIndex < _practiceSigns.length - 1) {
        _currentSignIndex++;
        _remainingTime = _sessionDuration;
      } else {
        _stopPractice();
        // Practice completed
        _showCompletionDialog();
      }
    });
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            const Text('Practice Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Great job! You\'ve practiced all the signs.'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 25),
              decoration: BoxDecoration(
                color: RiveAppTheme.accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Total Score: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text('$_score points',
                      style: TextStyle(color: RiveAppTheme.accentColor, fontWeight: FontWeight.bold)),
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
            child: Text('Close', style: TextStyle(color: Colors.grey[700])),
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

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get available safe area to avoid overlapping with system UI
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;
    
    return Container(
      color: RiveAppTheme.background,
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
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                // Help button positioned far right to avoid overlap
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                ? _buildPracticeView()
                : _buildPracticeSetupView(),
          ),
          
          // Increased bottom padding for tab bar
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPracticeSetupView() {
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Session Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Session Duration:'),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<int>(
                            value: _sessionDuration,
                            underline: const SizedBox(),
                            isDense: true,
                            items: [30, 45, 60, 90].map<DropdownMenuItem<int>>((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value sec'),
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
                        const Text('Signs to Practice:'),
                        Text(
                          '${_practiceSigns.length} signs',
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.lightbulb_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tip: Position yourself in a well-lit area for better sign recognition',
                      style: TextStyle(color: Colors.black87, fontSize: 12),
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

  Widget _buildPracticeView() {
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
                  color: Colors.black87,
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                      const Text(
                        'Practice Sign:',
                        style: TextStyle(
                          fontSize: 14, 
                          color: Colors.black54,
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
                    style: const TextStyle(
                      fontSize: 30, 
                      fontWeight: FontWeight.bold,
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
        
        // Practice area - more efficient use of space
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.withOpacity(0.1),
                  Colors.black.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Stack(
              children: [
                // Camera placeholder
                const Center(
                  child: Text(
                    'Camera View\n(MediaPipe integration needed)',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black45, fontSize: 13),
                  ),
                ),
                
                // Hand outline guide overlay
                Center(
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: RiveAppTheme.accentColor.withOpacity(0.5),
                        width: 2,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(90),
                    ),
                  ),
                ),
                
                // Camera controls - positioned higher to avoid bottom nav
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Controls row - more compact and moved up
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Stop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black54,
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
}