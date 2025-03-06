import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class TabItem {
  TabItem({
    this.stateMachine = "",
    this.artboard = "",
    this.status,
    this.title = "",
    this.icon,
  });

  UniqueKey? id = UniqueKey();
  String stateMachine;
  String artboard;
  late SMIBool? status;
  String title; // Added title for accessibility and screen identification
  IconData? icon; // Added fallback icon

  static List<TabItem> tabItemsList = [
    TabItem(
      stateMachine: "CHAT_Interactivity", 
      artboard: "CHAT",
      title: "Chat",
      icon: Icons.chat,
    ),
    TabItem(
      stateMachine: "SEARCH_Interactivity", 
      artboard: "SEARCH",
      title: "Search",
      icon: Icons.search,
    ),
    TabItem(
      stateMachine: "TIMER_Interactivity", 
      artboard: "TIMER",
      title: "Practice",
      icon: Icons.timer,
    ),
    TabItem(
      stateMachine: "BELL_Interactivity", 
      artboard: "BELL",
      title: "Notifications",
      icon: Icons.notifications,
    ),
    TabItem(
      stateMachine: "USER_Interactivity", 
      artboard: "USER",
      title: "Profile",
      icon: Icons.person,
    ),
  ];
}
