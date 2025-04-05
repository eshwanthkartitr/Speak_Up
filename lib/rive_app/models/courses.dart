import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CourseModel {
  CourseModel({
    this.id,
    this.title = "",
    this.subtitle = "",
    this.caption = "",
    this.color = Colors.white,
    this.image = "",
    this.icon,
    this.progress = 0.0,
    this.xpReward = 0,
    this.lessons = const [],
  });

  UniqueKey? id = UniqueKey();
  String title, caption, image;
  String? subtitle;
  Color color;
  IconData? icon; // FontAwesome icons for sharper visuals
  double progress; // Track user progress (0.0 - 1.0)
  int xpReward; // XP points reward for completing
  List<LessonModel> lessons; // List of lessons in this course

  // Helper method to get the icon based on the course title if none is specified
  IconData getIcon() {
    if (icon != null) return icon!;

    // Default icons based on title
    switch (title.toLowerCase()) {
      case "basic signs":
        return FontAwesomeIcons.hands;
      case "conversational signs":
        return FontAwesomeIcons.peopleGroup;
      case "advanced expressions":
        return FontAwesomeIcons.faceSmile;
      case "finger spelling":
        return FontAwesomeIcons.hand;
      case "daily practice":
        return FontAwesomeIcons.calendarCheck;
      case "vocabulary drill":
        return FontAwesomeIcons.bookOpen;
      case "conversation challenge":
        return FontAwesomeIcons.comments;
      default:
        return FontAwesomeIcons.handsAslInterpreting;
    }
  }

  // Main course paths
  static List<CourseModel> courses = [
    CourseModel(
      title: "Basic Signs",
      subtitle: "Essential everyday signs to start communicating",
      caption: "20 lessons - Beginner",
      color: const Color(0xFF5E60CE),
      icon: FontAwesomeIcons.handsPraying,
      progress: 0.65,
      xpReward: 100,
      lessons: [
        LessonModel(
          title: "Greetings & Introductions",
          description: "Learn how to say hello, goodbye, and introduce yourself",
          duration: "10 min",
          difficulty: "Easy",
        ),
        LessonModel(
          title: "Common Questions",
          description: "Master signs for who, what, where, when, why and how",
          duration: "15 min",
          difficulty: "Easy",
        ),
        LessonModel(
          title: "Numbers 1-20",
          description: "Learn to count and express quantities in sign language",
          duration: "12 min",
          difficulty: "Easy",
        ),
        LessonModel(
          title: "Family Members",
          description: "Signs for mother, father, sister, brother and other family relations",
          duration: "15 min",
          difficulty: "Medium",
        ),
        LessonModel(
          title: "Colors & Descriptions",
          description: "Express visual attributes and colors",
          duration: "10 min",
          difficulty: "Easy",
        ),
      ],
    ),
    CourseModel(
      title: "Converse \nwith Signs",
      subtitle: "Learn flowing Tamil sign conversations for everyday situations",
      caption: "15 lessons - Intermediate",
      color: const Color(0xFF4EA8DE),
      icon: FontAwesomeIcons.handshake,
      progress: 0.3,
      xpReward: 150,
      lessons: [
        LessonModel(
          title: "At the Restaurant",
          description: "Order food, ask for recommendations, and pay the bill",
          duration: "20 min",
          difficulty: "Medium",
        ),
        LessonModel(
          title: "Shopping Conversations",
          description: "Ask about products, prices, and sizes while shopping",
          duration: "18 min",
          difficulty: "Medium",
        ),
        LessonModel(
          title: "Travel & Directions",
          description: "Ask for and give directions, discuss transportation options",
          duration: "25 min",
          difficulty: "Medium",
        ),
        LessonModel(
          title: "Healthcare Communication",
          description: "Explain symptoms, understand medical instructions",
          duration: "30 min",
          difficulty: "Hard",
        ),
        LessonModel(
          title: "Academic Discussions",
          description: "Signs related to school, subjects, and learning",
          duration: "22 min",
          difficulty: "Medium",
        ),
      ],
    ),
    CourseModel(
      title: "Advanced Expressions",
      subtitle: "Master complex expressions and cultural nuances in Tamil Sign Language",
      caption: "12 lessons - Advanced",
      color: const Color(0xFF7209B7),
      icon: FontAwesomeIcons.faceSmileWink,
      progress: 0.1,
      xpReward: 200,
      lessons: [
        LessonModel(
          title: "Emotions & Nuances",
          description: "Express complex emotions and subtle feelings",
          duration: "25 min",
          difficulty: "Hard",
        ),
        LessonModel(
          title: "Cultural References",
          description: "Learn signs related to Tamil culture and traditions",
          duration: "30 min",
          difficulty: "Hard",
        ),
        LessonModel(
          title: "Idiomatic Expressions",
          description: "Master common idioms and expressions in sign language",
          duration: "28 min",
          difficulty: "Hard",
        ),
        LessonModel(
          title: "Professional Vocabulary",
          description: "Signs for work environments and professional settings",
          duration: "35 min",
          difficulty: "Hard",
        ),
        LessonModel(
          title: "Poetry & Storytelling",
          description: "Advanced techniques for expressive storytelling",
          duration: "40 min",
          difficulty: "Expert",
        ),
      ],
    ),
  ];

  // Daily challenges and practice sessions
  static List<CourseModel> courseSections = [
    CourseModel(
      title: "Daily Practice",
      caption: "5 minute practice - Earn 20 XP",
      color: const Color(0xFFF72585),
      icon: FontAwesomeIcons.calendarDay,
      xpReward: 20,
      lessons: [
        LessonModel(
          title: "Everyday Greetings",
          description: "Quick practice of common greetings",
          duration: "5 min",
          difficulty: "Easy",
        ),
      ],
    ),
    CourseModel(
      title: "Finger Spelling",
      caption: "Learn Tamil alphabet - Earn 15 XP",
      color: const Color(0xFF4CC9F0),
      icon: FontAwesomeIcons.hand,
      xpReward: 15,
      lessons: [
        LessonModel(
          title: "Letters A-M",
          description: "First half of the alphabet in sign language",
          duration: "10 min",
          difficulty: "Medium",
        ),
        LessonModel(
          title: "Letters N-Z",
          description: "Second half of the alphabet in sign language",
          duration: "10 min",
          difficulty: "Medium",
        ),
      ],
    ),
    CourseModel(
      title: "Vocabulary Drill",
      caption: "30 essential words - Earn 25 XP",
      color: const Color(0xFF4895EF),
      icon: FontAwesomeIcons.bookOpen,
      xpReward: 25,
      lessons: [
        LessonModel(
          title: "Common Objects",
          description: "Signs for everyday items around you",
          duration: "15 min",
          difficulty: "Easy",
        ),
        LessonModel(
          title: "Action Words",
          description: "Essential verbs for expressing activities",
          duration: "15 min",
          difficulty: "Medium",
        ),
      ],
    ),
    CourseModel(
      title: "Conversation Challenge",
      caption: "Practice dialogue - Earn 35 XP",
      color: const Color(0xFF3F37C9),
      icon: FontAwesomeIcons.comments,
      xpReward: 35,
      lessons: [
        LessonModel(
          title: "Introduce Yourself",
          description: "Practice a full introduction conversation",
          duration: "20 min",
          difficulty: "Medium",
        ),
        LessonModel(
          title: "Making Plans",
          description: "Arrange meetings and activities with friends",
          duration: "25 min",
          difficulty: "Hard",
        ),
      ],
    ),
  ];
}

class LessonModel {
  final String title;
  final String description;
  final String duration;
  final String difficulty;
  final bool isCompleted;
  
  LessonModel({
    required this.title,
    required this.description,
    required this.duration,
    required this.difficulty,
    this.isCompleted = false,
  });
}
