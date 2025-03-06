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
  });

  UniqueKey? id = UniqueKey();
  String title, caption, image;
  String? subtitle;
  Color color;
  IconData? icon; // FontAwesome icons for sharper visuals
  double progress; // Track user progress (0.0 - 1.0)
  int xpReward; // XP points reward for completing

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
    ),
    CourseModel(
      title: "Converse \nwith Signs",
      subtitle: "Learn flowing Tamil sign conversations for everyday situations",
      caption: "15 lessons - Intermediate",
      color: const Color(0xFF4EA8DE),
      icon: FontAwesomeIcons.handshake,
      progress: 0.3,
      xpReward: 150,
    ),
    CourseModel(
      title: "Advanced Expressions",
      subtitle: "Master complex expressions and cultural nuances in Tamil Sign Language",
      caption: "12 lessons - Advanced",
      color: const Color(0xFF7209B7),
      icon: FontAwesomeIcons.faceSmileWink,
      progress: 0.1,
      xpReward: 200,
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
    ),
    CourseModel(
      title: "Finger Spelling",
      caption: "Learn Tamil alphabet - Earn 15 XP",
      color: const Color(0xFF4CC9F0),
      icon: FontAwesomeIcons.hand,
      xpReward: 15,
    ),
    CourseModel(
      title: "Vocabulary Drill",
      caption: "30 essential words - Earn 25 XP",
      color: const Color(0xFF4895EF),
      icon: FontAwesomeIcons.bookOpen,
      xpReward: 25,
    ),
    CourseModel(
      title: "Conversation Challenge",
      caption: "Practice dialogue - Earn 35 XP",
      color: const Color(0xFF3F37C9),
      icon: FontAwesomeIcons.comments,
      xpReward: 35,
    ),
  ];
}
