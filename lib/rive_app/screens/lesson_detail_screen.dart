import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/models/courses.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:math' as math;

class LessonDetailScreen extends StatefulWidget {
  final CourseModel course;

  const LessonDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  bool _videoWatched = false;
  bool _quizCompleted = false;
  int _currentQuestionIndex = 0;
  int _score = 0;

  // Mock questions for the quiz
  final List<Map<String, dynamic>> _quizQuestions = [
    {
      'question': 'What is the primary purpose of sign language?',
      'options': [
        'To communicate with animals',
        'To communicate visually without speaking',
        'To communicate secretly in public',
        'To improve hand-eye coordination'
      ],
      'correctAnswer': 1,
    },
    {
      'question': 'Which finger is typically used to represent the letter "I" in ASL?',
      'options': [
        'Thumb',
        'Index finger',
        'Middle finger',
        'Pinky finger'
      ],
      'correctAnswer': 3,
    },
    {
      'question': 'How do you express a question in sign language?',
      'options': [
        'By signing a question mark',
        'By raising your eyebrows and tilting your head forward',
        'By waving both hands',
        'By pointing at the person you\'re asking'
      ],
      'correctAnswer': 1,
    },
  ];

  void _launchYoutubeVideo() {
    // Show a dialog that simulates watching a video
    String videoTitle = '';
    
    switch (widget.course.title) {
      case "Daily Practice":
        videoTitle = "Daily Practice - Basic Greetings";
        break;
      case "Finger Spelling":
        videoTitle = "Finger Spelling - Letters A-Z";
        break;
      case "Vocabulary Drill":
        videoTitle = "Vocabulary Drill - Common Objects";
        break;
      case "Conversation Challenge":
        videoTitle = "Conversation Challenge - Introduction";
        break;
      default:
        videoTitle = "Sign Language Tutorial";
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Watch Video"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              videoTitle,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "This is a simulation of watching the video tutorial. In a real app, this would launch YouTube or play the video within the app.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Mark video as watched
              setState(() {
                _videoWatched = true;
              });
            },
            child: Text("Complete Video"),
          ),
        ],
      ),
    );
  }

  void _answerQuestion(int selectedOption) {
    final isCorrect = selectedOption == _quizQuestions[_currentQuestionIndex]['correctAnswer'];
    
    if (isCorrect) {
      setState(() {
        _score++;
      });
    }
    
    if (_currentQuestionIndex < _quizQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // Quiz completed
      setState(() {
        _quizCompleted = true;
      });
      
      // Show completion dialog
      _showQuizResultDialog();
    }
  }

  void _showQuizResultDialog() {
    final percentage = (_score / _quizQuestions.length) * 100;
    final isPassed = percentage >= 70; // Pass threshold is 70%
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isPassed ? 'Congratulations!' : 'Keep Learning!',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPassed ? Icons.check_circle : Icons.info,
              color: isPassed ? Colors.green : Colors.orange,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'You scored $_score out of ${_quizQuestions.length}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              isPassed 
                ? 'You\'ve successfully completed this lesson!'
                : 'Review the material and try again.',
              textAlign: TextAlign.center,
            ),
            if (isPassed) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amber),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '+${widget.course.xpReward} XP',
                      style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (isPassed) {
                Navigator.of(context).pop(); // Return to previous screen
              } else {
                // Reset quiz to try again
                setState(() {
                  _currentQuestionIndex = 0;
                  _score = 0;
                  _quizCompleted = false;
                });
              }
            },
            child: Text(isPassed ? 'Complete' : 'Try Again'),
          ),
        ],
      ),
    );
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
        title: Text(
          widget.course.title,
          style: TextStyle(
            color: RiveAppTheme.getTextColor(isDarkMode),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: RiveAppTheme.getTextColor(isDarkMode),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with course info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [widget.course.color, widget.course.color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: widget.course.color.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Course icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        widget.course.getIcon(),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Course info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.course.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: "Poppins",
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.course.caption,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade600,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.bolt, color: Colors.white, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      "${widget.course.xpReward} XP",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Video section
              Text(
                "Lesson Video",
                style: TextStyle(
                  color: RiveAppTheme.getTextColor(isDarkMode),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Video thumbnail or placeholder
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: Colors.black.withOpacity(0.1),
                        width: double.infinity,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(
                              widget.course.getIcon(),
                              size: 48,
                              color: widget.course.color.withOpacity(0.7),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Learn ${widget.course.title}",
                              style: TextStyle(
                                color: RiveAppTheme.getTextColor(isDarkMode),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Play button overlay
                    ElevatedButton.icon(
                      onPressed: _launchYoutubeVideo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.course.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 24),
                      label: const Text(
                        "Watch Video",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    // Watched indicator
                    if (_videoWatched)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Quiz section
              if (_videoWatched) ...[
                Text(
                  "Knowledge Check",
                  style: TextStyle(
                    color: RiveAppTheme.getTextColor(isDarkMode),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: "Poppins",
                  ),
                ),
                const SizedBox(height: 12),
                if (!_quizCompleted) ...[
                  // Current question
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode ? RiveAppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question progress indicator
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: widget.course.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "Question ${_currentQuestionIndex + 1}/${_quizQuestions.length}",
                                style: TextStyle(
                                  color: widget.course.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Question text
                        Text(
                          _quizQuestions[_currentQuestionIndex]['question'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: RiveAppTheme.getTextColor(isDarkMode),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Answer options
                        ...List.generate(
                          _quizQuestions[_currentQuestionIndex]['options'].length,
                          (index) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ElevatedButton(
                              onPressed: () => _answerQuestion(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDarkMode 
                                    ? Colors.grey[800] 
                                    : Colors.grey[100],
                                foregroundColor: RiveAppTheme.getTextColor(isDarkMode),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, 
                                  vertical: 16,
                                ),
                                alignment: Alignment.centerLeft,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: widget.course.color.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        String.fromCharCode(65 + index), // A, B, C, D
                                        style: TextStyle(
                                          color: widget.course.color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _quizQuestions[_currentQuestionIndex]['options'][index],
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: RiveAppTheme.getTextColor(isDarkMode),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Quiz completed state
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode ? RiveAppTheme.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Quiz Completed!",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: RiveAppTheme.getTextColor(isDarkMode),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "You scored $_score out of ${_quizQuestions.length}",
                          style: TextStyle(
                            fontSize: 16,
                            color: RiveAppTheme.getTextColor(isDarkMode),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Text(
                                '+${widget.course.xpReward} XP',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ] else ...[
                // Video not watched yet - prompt
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? RiveAppTheme.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.amber.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.amber,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Watch the video first",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: RiveAppTheme.getTextColor(isDarkMode),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Complete the video lesson to unlock the quiz and earn XP",
                              style: TextStyle(
                                color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 