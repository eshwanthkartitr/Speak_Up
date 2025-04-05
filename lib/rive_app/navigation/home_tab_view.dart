import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/components/hcard.dart';
import 'package:flutter_samples/rive_app/components/vcard.dart';
import 'package:flutter_samples/rive_app/models/courses.dart';
import 'package:flutter_samples/rive_app/models/menu_item.dart';
import 'package:flutter_samples/rive_app/models/user_model.dart';
import 'package:flutter_samples/rive_app/screens/character_playground_screen.dart';
import 'package:flutter_samples/rive_app/screens/chat_screen.dart';
import 'package:flutter_samples/rive_app/screens/learning_path_screen.dart';
import 'package:flutter_samples/rive_app/screens/lesson_detail_screen.dart';
import 'package:flutter_samples/rive_app/services/user_provider.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import 'package:flutter_samples/rive_app/assets.dart' as app_assets;

class HomeTabView extends StatefulWidget {
  const HomeTabView({Key? key}) : super(key: key);

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> with SingleTickerProviderStateMixin {
  final List<CourseModel> _courses = CourseModel.courses;
  final List<CourseModel> _courseSections = CourseModel.courseSections;

  // User stats for gamification
  final int _currentStreak = 7;
  final int _xpPoints = 450;
  final int _todayXP = 30;
  final int _level = 5;
  
  // Animation controllers for Rive
  StateMachineController? _riveController;
  SMITrigger? _riveButtonTrigger;
  
  // Stores the current active animation
  String _activeButton = '';
  
  void _onRiveInit(Artboard artboard, String stateMachineName) {
    final controller = StateMachineController.fromArtboard(
      artboard, 
      stateMachineName,
    );
    
    if (controller != null) {
      artboard.addController(controller);
      _riveController = controller;
      final trigger = controller.findInput<bool>('Trigger');
      if (trigger != null) {
        _riveButtonTrigger = trigger as SMITrigger;
      } else {
        print('Warning: Trigger input not found in Rive animation');
      }
    }
  }
  
  void _navigateWithAnimation(BuildContext context, Widget destination, String buttonId) {
    // Mark which button is being pressed
    setState(() {
      _activeButton = buttonId;
    });
    
    // Trigger animation
    _riveButtonTrigger?.fire();
    
    // Navigate after a delay
    Future.delayed(const Duration(milliseconds: 800), () {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            var begin = const Offset(0.0, 1.0);
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
        ),
      ).then((_) {
        // Reset active button when returning
        setState(() {
          _activeButton = '';
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get ThemeProvider instance
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: RiveAppTheme.getBackgroundColor(isDarkMode),
          borderRadius: BorderRadius.circular(30),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 80,
              bottom: MediaQuery.of(context).padding.bottom + 70),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User stats and gamification elements
              _buildUserStats(isDarkMode),

              // Learning Path button
              _buildLearningPathButton(isDarkMode),

              const SizedBox(height: 20),

              // Lessons section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.graduationCap,
                      size: 24,
                      color: RiveAppTheme.getTextColor(isDarkMode),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Must Learn",
                      style: TextStyle(
                        fontSize: 28,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                        color: RiveAppTheme.getTextColor(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),

              // Lesson categories
              SizedBox(
                height: 320,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  scrollDirection: Axis.horizontal,
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      key: _courses[index].id,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 20),
                      child: VCard(course: _courses[index]),
                    );
                  },
                ),
              ),

              // Daily challenges section
              Padding(
                padding: const EdgeInsets.only(
                    left: 20, right: 20, bottom: 20, top: 10),
                child: Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.fire,
                      size: 22,
                      color: isDarkMode ? Colors.deepOrange[300] : Colors.deepOrange,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Daily Challenges",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                        color: RiveAppTheme.getTextColor(isDarkMode),
                      ),
                    ),
                  ],
                ),
              ),

              // Daily challenge cards
              _buildDailyChallenges(isDarkMode),

              // AI Conversation section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: _buildAIConversationCard(isDarkMode),
              ),

              // Playground feature button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: _buildPlaygroundCard(isDarkMode),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // User stats bar with gamification elements
  Widget _buildUserStats(bool isDarkMode) {
    final userProvider = Provider.of<UserProvider>(context);
    final isAuthenticated = userProvider.isAuthenticated;
    
    // Get user stats from provider if authenticated, else use default values
    final level = isAuthenticated ? userProvider.currentUser!.level : _level;
    final xpPoints = isAuthenticated ? userProvider.currentUser!.xpPoints : _xpPoints;
    final currentStreak = isAuthenticated ? userProvider.currentUser!.streak : _currentStreak;
    final todayXP = _todayXP; // This is still hardcoded as it's not stored in the database
    
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode 
              ? [Colors.blue.shade900, Colors.indigo.shade900]
              : [Colors.blue.shade700, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade700).withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Level indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "LEVEL",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.only(left: 5.0, right: 5.0),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$level",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "($xpPoints XP)",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Streak indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_fire_department,
                    color: Colors.amber,
                    size: 24,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "$currentStreak DAY STREAK",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                "+$todayXP XP Today",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Learning Path button
  Widget _buildLearningPathButton(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: InkWell(
        onTap: () {
          _navigateWithAnimation(context, const LearningPathScreen(), 'learning_path');
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDarkMode
                  ? [Colors.green.shade800, Colors.teal.shade900]
                  : [Colors.green.shade400, Colors.teal.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: (isDarkMode ? Colors.teal.shade900 : Colors.teal.shade300).withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.road,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Learning Path",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: "Poppins",
                          ),
                        ),
                        Text(
                          "Follow your personalized sign language journey",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
              if (_activeButton == 'learning_path')
                Positioned.fill(
                  child: SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: RiveAnimation.asset(
                      app_assets.confettiRiv,
                      fit: BoxFit.cover,
                      onInit: (artboard) => _onRiveInit(artboard, 'State Machine 1'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // AI Conversation card
  Widget _buildAIConversationCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.purple.shade900, Colors.deepPurple.shade900]
              : [Colors.purple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.deepPurple.shade900 : Colors.deepPurple.shade300).withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  FaIcon(
                    FontAwesomeIcons.robot,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Practice with AI",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Have a conversation in sign language with our AI assistant. Practice your skills and get instant feedback.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: "Inter",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _navigateWithAnimation(context, const ChatScreen(), 'chat');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isDarkMode ? Colors.deepPurple.shade300 : Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.comments, size: 16),
                    label: const Text(
                      "Start Conversation",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_activeButton == 'chat')
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: RiveAnimation.asset(
                    app_assets.confettiRiv,
                    fit: BoxFit.cover,
                    onInit: (artboard) => _onRiveInit(artboard, 'State Machine 1'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Playground feature card
  Widget _buildPlaygroundCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.orange.shade900, Colors.deepOrange.shade900]
              : [Colors.orange.shade400, Colors.deepOrange.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isDarkMode ? Colors.deepOrange.shade900 : Colors.deepOrange.shade300).withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  FaIcon(
                    FontAwesomeIcons.gamepad,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Character Playground",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Poppins",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "Practice character recognition with our AI model. Get real-time predictions and word suggestions based on detected characters.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: "Inter",
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      _navigateWithAnimation(context, const CharacterPlaygroundScreen(), 'playground');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: isDarkMode ? Colors.deepOrange.shade300 : Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const FaIcon(FontAwesomeIcons.play, size: 16),
                    label: const Text(
                      "Start Playground",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_activeButton == 'playground')
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: RiveAnimation.asset(
                    app_assets.confettiRiv,
                    fit: BoxFit.cover,
                    onInit: (artboard) => _onRiveInit(artboard, 'State Machine 1'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Daily challenge cards
  Widget _buildDailyChallenges(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Daily Challenges",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Poppins",
                ),
              ),
              Text(
                "See All",
                style: TextStyle(
                  color: Colors.blue,
                  fontFamily: "Poppins",
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180, // Updated height to match HCard
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 20),
            scrollDirection: Axis.horizontal,
            itemCount: CourseModel.courseSections.length,
            itemBuilder: (BuildContext context, int index) {
              final course = CourseModel.courseSections[index];
              return HCard(course: course);
            },
          ),
        ),
      ],
    );
  }

  // Floating action button for real-time translation
  Widget _buildTranslateButton(bool isDarkMode) {
    return FloatingActionButton.extended(
      onPressed: () {},
      backgroundColor: isDarkMode ? Colors.green.shade800 : Colors.green.shade600,
      label: const Text(
        "Translate Now",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
      icon: const FaIcon(FontAwesomeIcons.language, color: Colors.white),
      elevation: 8,
    );
  }
}
