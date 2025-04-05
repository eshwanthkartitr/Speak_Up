import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'dart:math';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_samples/rive_app/models/courses.dart';
import 'package:flutter_samples/rive_app/screens/lesson_detail_screen.dart';

// Custom page route for beautiful transitions
class SlidePageRoute extends PageRouteBuilder {
  final Widget page;
  
  SlidePageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = const Offset(1.0, 0.0);
            var end = Offset.zero;
            var curve = Curves.easeOutCubic;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );
}

class LearningPathScreen extends StatefulWidget {
  const LearningPathScreen({Key? key}) : super(key: key);

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen>
    with TickerProviderStateMixin {
  // Controllers for animations
  late AnimationController _progressController;
  late AnimationController _headerController;
  late AnimationController _contentController;
  late Animation<double> _progressAnimation;
  late Animation<double> _headerScaleAnimation;
  late Animation<double> _headerSlideAnimation;
  
  // Track the currently selected node
  int _selectedNodeIndex = 0;
  bool _isPathLoaded = false;

  // Learning path data
  final List<Map<String, dynamic>> _pathNodes = [
    {
      'id': 'basics',
      'title': 'ASL Basics',
      'description': 'Learn foundational hand shapes and greetings',
      'xp': 50,
      'isCompleted': true,
      'icon': FontAwesomeIcons.handPeace,
    },
    {
      'id': 'alphabet',
      'title': 'Alphabet Mastery',
      'description': 'Learn to sign the complete alphabet',
      'xp': 100,
      'isCompleted': true,
      'icon': FontAwesomeIcons.font,
    },
    {
      'id': 'numbers',
      'title': 'Numbers & Counting',
      'description': 'Learn numbers and basic counting',
      'xp': 75,
      'isCompleted': false,
      'icon': FontAwesomeIcons.calculator,
    },
    {
      'id': 'common_phrases',
      'title': 'Common Phrases',
      'description': 'Everyday expressions and questions',
      'xp': 120,
      'isCompleted': false,
      'icon': FontAwesomeIcons.commentDots,
    },
    {
      'id': 'conversation',
      'title': 'Basic Conversation',
      'description': 'Put it all together in simple dialogues',
      'xp': 150,
      'isCompleted': false,
      'icon': FontAwesomeIcons.peopleGroup,
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Setup header animations
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerScaleAnimation = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    );
    _headerSlideAnimation = Tween<double>(begin: -50, end: 0).animate(
      CurvedAnimation(
        parent: _headerController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Setup progress animations
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _progressController, 
        curve: Curves.easeInOutCubic,
      ),
    );
    
    // Setup content animations
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    // Start animations in sequence
    _headerController.forward().then((value) {
      _progressController.forward().then((value) {
        setState(() {
          _isPathLoaded = true;
        });
        _contentController.forward();
      });
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme provider to access dark mode state
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: RiveAppTheme.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Learning Path", 
          style: TextStyle(fontFamily: "Poppins", fontWeight: FontWeight.w600),
        ),
        leading: Hero(
          tag: 'back_button',
          child: Material(
            color: Colors.transparent,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress header with animations
          AnimatedBuilder(
            animation: _headerController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _headerSlideAnimation.value),
                child: Transform.scale(
                  scale: _headerScaleAnimation.value,
                  child: Opacity(
                    // Use clamp to ensure opacity is always between 0.0 and 1.0
                    opacity: _headerScaleAnimation.value.clamp(0.0, 1.0),
                    child: _buildProgressHeader(),
                  ),
                ),
              );
            },
          ),
          
          // Learning path visualization
          Expanded(
            child: _isPathLoaded 
                ? AnimationLimiter(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _pathNodes.length,
                      itemBuilder: (context, index) {
                        final bool isLast = index == _pathNodes.length - 1;
                        final node = _pathNodes[index];
                        final bool isCompleted = node['isCompleted'] as bool;
                        final bool isCurrent = !isCompleted && 
                          (index == 0 || _pathNodes[index - 1]['isCompleted'] == true);
                        final bool isLocked = !isCompleted && !isCurrent;
                        
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 600),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Column(
                                children: [
                                  // Node item
                                  _buildPathNode(
                                    node: node,
                                    isCompleted: isCompleted,
                                    isCurrent: isCurrent,
                                    isLocked: isLocked,
                                    index: index,
                                  ),
                                  
                                  // Connecting line with animation
                                  if (!isLast)
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 600),
                                      curve: Curves.easeInOut,
                                      margin: const EdgeInsets.only(left: 36),
                                      width: 4,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isCompleted 
                                          ? Colors.green.withOpacity(0.7) 
                                          : Colors.grey.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(2),
                                        boxShadow: isCompleted ? [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 0.5,
                                          )
                                        ] : [],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ],
      ),
      // Add floating action button for enhanced UX
      floatingActionButton: AnimatedBuilder(
        animation: _contentController,
        builder: (context, child) {
          return Transform.scale(
            scale: _contentController.value,
            child: FloatingActionButton(
              onPressed: () {
                // Find current lesson and navigate to it
                int currentIndex = _pathNodes.indexWhere((node) => 
                  node['isCompleted'] == false && 
                  (_pathNodes[_pathNodes.indexOf(node) - 1]['isCompleted'] == true));
                if (currentIndex >= 0) {
                  setState(() {
                    _selectedNodeIndex = currentIndex;
                  });
                  _showLessonDetails(_pathNodes[currentIndex]);
                }
              },
              backgroundColor: Colors.blue.shade600,
              child: const Icon(Icons.play_arrow_rounded, size: 32),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildProgressHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Hero widget for smooth transition from home page
              const Hero(
                tag: 'learning_path_title',
                child: Material(
                  color: Colors.transparent,
                  child: Text(
                    "Beginner Track",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Animated badge
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade600,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "BEGINNER",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated progress bar
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 0.4),  // 40% complete
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              // Background
                              Container(
                                height: 10,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              // Progress
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 1500),
                                curve: Curves.easeOutCubic,
                                height: 10,
                                width: MediaQuery.of(context).size.width * 0.8 * value,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.amber.shade300, Colors.amber.shade600],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withOpacity(0.5),
                                      blurRadius: 6,
                                      spreadRadius: -1,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "${(_progressAnimation.value * 40).toInt()}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: "% Complete",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  "2/5 Lessons",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildPathNode({
    required Map<String, dynamic> node,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLocked,
    required int index,
  }) {
    Color nodeColor = isCompleted 
        ? Colors.green 
        : (isCurrent ? Colors.blue : Colors.grey);
    
    return GestureDetector(
      onTap: isLocked ? null : () {
        setState(() {
          _selectedNodeIndex = index;
        });
        // Provide haptic feedback
        HapticFeedback.mediumImpact();
        
        // Navigate to lesson details with animated route
        if (isCompleted || isCurrent) {
          _showLessonDetails(node);
        }
      },
      child: Hero(
        tag: 'path_node_${node['id']}',
        child: Material(
          color: Colors.transparent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedNodeIndex == index 
                  ? nodeColor.withOpacity(0.15)
                  : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: nodeColor.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: _selectedNodeIndex == index ? [
                BoxShadow(
                  color: nodeColor.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                )
              ] : [],
            ),
            child: Row(
              children: [
                // Animated icon container
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.0, end: _selectedNodeIndex == index ? 1.2 : 1.0),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              nodeColor.withOpacity(0.7),
                              nodeColor.withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(color: nodeColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: nodeColor.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isCompleted
                              ? const Icon(
                                  FontAwesomeIcons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                              : (isLocked
                                  ? Icon(
                                      FontAwesomeIcons.lock,
                                      color: Colors.white.withOpacity(0.8),
                                      size: 22,
                                    )
                                  : ShakeAnimatedWidget(
                                      enabled: isCurrent,
                                      duration: const Duration(milliseconds: 1500),
                                      shakeAngle: Rotation.deg(z: 5),
                                      curve: Curves.elasticOut,
                                      child: Icon(
                                        node['icon'] as IconData,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    )),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                // Lesson info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            node['title'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isLocked ? Colors.grey : Colors.black87,
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        nodeColor.withOpacity(0.7),
                                        nodeColor.withOpacity(0.3),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: nodeColor.withOpacity(0.2),
                                        blurRadius: 4,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    "+${node['xp']} XP",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        node['description'] as String,
                        style: TextStyle(
                          color: isLocked ? Colors.grey : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      if (isCurrent)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.play_circle_filled,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "CONTINUE",
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Add a new method to show lesson details
  void _showLessonDetails(Map<String, dynamic> node) {
    final bool isCompleted = node['isCompleted'] as bool;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 20),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  
                  // Title section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            node['icon'] as IconData,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                node['title'] as String,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                node['description'] as String,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    child: Divider(color: Colors.grey[300], height: 1),
                  ),
                  
                  // Lessons list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: 5, // Simulating 5 lessons per node
                      itemBuilder: (context, index) {
                        // Create sample lesson names based on the node title
                        final lessonTitle = "Lesson ${index + 1}: ${node['title']} ${index + 1}";
                        final isLessonCompleted = isCompleted || (index == 0 && !isCompleted);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isLessonCompleted ? Colors.grey[100] : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isLessonCompleted ? Colors.green.withOpacity(0.3) : Colors.grey[300]!,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isLessonCompleted ? Colors.green.withOpacity(0.1) : Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isLessonCompleted
                                      ? const Icon(Icons.check_circle, color: Colors.green)
                                      : Text(
                                          "${index + 1}",
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                lessonTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isLessonCompleted ? Colors.black87 : Colors.grey[600],
                                ),
                              ),
                              subtitle: Text(
                                "Duration: 10-15 minutes",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: isLessonCompleted ? Colors.grey[600] : Colors.grey[400],
                              ),
                              onTap: () {
                                // Navigate to the lesson screen
                                Navigator.pop(context);
                                
                                // Create a CourseModel from the node data
                                final courseModel = CourseModel(
                                  title: node['title'],
                                  caption: node['description'],
                                  color: isCompleted ? Colors.green : Colors.blue,
                                  icon: node['icon'] as IconData,
                                  progress: isCompleted ? 1.0 : 0.0,
                                  xpReward: node['xp'] as int,
                                );
                                
                                // Navigate to the lesson detail screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LessonDetailScreen(
                                      course: courseModel,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Custom animation widget for shaking effect
class ShakeAnimatedWidget extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Duration duration;
  final ShakeAngle shakeAngle;
  final Curve curve;

  const ShakeAnimatedWidget({
    Key? key,
    required this.child,
    this.enabled = true,
    this.duration = const Duration(milliseconds: 1000),
    this.shakeAngle = const ShakeAngle(z: 0.17453292519943295), // ~10 degrees in radians
    this.curve = Curves.elasticOut,
  }) : super(key: key);

  @override
  State<ShakeAnimatedWidget> createState() => _ShakeAnimatedWidgetState();
}

class _ShakeAnimatedWidgetState extends State<ShakeAnimatedWidget> with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (widget.enabled) {
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && widget.enabled) {
                controller.forward(from: 0.0);
              }
            });
          }
        }
      });
    
    animation = CurvedAnimation(parent: controller, curve: widget.curve);
    
    if (widget.enabled) {
      controller.forward();
    }
  }

  @override
  void didUpdateWidget(ShakeAnimatedWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        controller.forward();
      } else {
        controller.stop();
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final sin = Curves.easeInOut.transform(
          (0.5 - (0.5 * animation.value)).abs() * 2,
        );
        return Transform.rotate(
          angle: sin * 0.05 * widget.shakeAngle.z,
          child: widget.child,
        );
      },
    );
  }
}

class ShakeAngle {
  final double x;
  final double y;
  final double z;

  const ShakeAngle({this.x = 0, this.y = 0, this.z = 0});
}

class Rotation {
  static ShakeAngle deg({double x = 0, double y = 0, double z = 0}) {
    return ShakeAngle(
      x: x * 0.0174533, // Convert to radians
      y: y * 0.0174533,
      z: z * 0.0174533,
    );
  }
}