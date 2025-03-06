import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/components/hcard.dart';
import 'package:flutter_samples/rive_app/components/vcard.dart';
import 'package:flutter_samples/rive_app/models/courses.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_samples/rive_app/screens/learning_path_screen.dart';

class HomeTabView extends StatefulWidget {
  const HomeTabView({Key? key}) : super(key: key);

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  final List<CourseModel> _courses = CourseModel.courses;
  final List<CourseModel> _courseSections = CourseModel.courseSections;

  // User stats for gamification
  final int _currentStreak = 7;
  final int _xpPoints = 450;
  final int _todayXP = 30;
  final int _level = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: RiveAppTheme.background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 60,
              bottom: MediaQuery.of(context).padding.bottom + 70),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User stats and gamification elements
              _buildUserStats(),

              // Learning Path button
              _buildLearningPathButton(),

              const SizedBox(height: 20),

              // Lessons section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: const [
                    FaIcon(FontAwesomeIcons.graduationCap, size: 24),
                    SizedBox(width: 10),
                    Text(
                      "Must Learn",
                      style: TextStyle(
                        fontSize: 28,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
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
                  children: const [
                    FaIcon(FontAwesomeIcons.fire,
                        size: 22, color: Colors.deepOrange),
                    SizedBox(width: 10),
                    Text(
                      "Daily Challenges",
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Daily challenges list
              ...List.generate(
                _courseSections.length,
                (index) => Padding(
                  key: _courseSections[index].id,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: HCard(section: _courseSections[index]),
                ),
              ),

              // AI Conversation section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: _buildAIConversationCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // User stats bar with gamification elements
  Widget _buildUserStats() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
            color: Colors.blue.shade700.withOpacity(0.3),
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
                      "$_level",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "($_xpPoints XP)",
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
                    "$_currentStreak DAY STREAK",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                "+$_todayXP XP Today",
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
  Widget _buildLearningPathButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            SlidePageRoute(
              page: const LearningPathScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.teal.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.shade300.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
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
        ),
      ),
    );
  }

  // AI Conversation card
  Widget _buildAIConversationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.deepPurple.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.shade300.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
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
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }

  // Floating action button for real-time translation
  Widget _buildTranslateButton() {
    return FloatingActionButton.extended(
      onPressed: () {},
      backgroundColor: Colors.green.shade600,
      label: const Text(
        "Translate Now",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      icon: const FaIcon(FontAwesomeIcons.language),
      elevation: 8,
    );
  }
}
