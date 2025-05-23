import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:flutter_samples/rive_app/services/user_provider.dart';
import 'package:flutter_samples/rive_app/models/user_model.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Additional user stats that aren't in UserModel
  final Map<String, dynamic> _additionalStats = {
    "joinDate": DateTime(2023, 9, 15),
    "totalPracticeTime": 1840, // in minutes
    "signsMastered": 48,
    "achievements": [
      {"name": "First Step", "description": "Complete your first lesson", "unlocked": true},
      {"name": "Week Warrior", "description": "Practice for 7 consecutive days", "unlocked": true},
      {"name": "Grammar Guru", "description": "Master 10 grammar concepts", "unlocked": true},
      {"name": "Vocabulary Master", "description": "Learn 50 signs", "unlocked": false},
      {"name": "Conversation Pro", "description": "Complete 5 conversation practices", "unlocked": true},
    ]
  };
  
  bool _notificationsEnabled = true;
  bool _practiceReminders = true;
  bool _dataSync = true;

  @override
  Widget build(BuildContext context) {
    // Get providers
    final themeProvider = Provider.of<ThemeProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    // Get user data
    final UserModel? user = userProvider.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("Please sign in to view your profile"),
        ),
      );
    }
    
    // Get available safe area to avoid overlapping with system UI
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;
    
    return Scaffold(
      backgroundColor: RiveAppTheme.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Profile',
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
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined, 
              color: RiveAppTheme.getTextColor(isDarkMode),
            ),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: 80, // Extra padding for tab bar
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile header
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    RiveAppTheme.accentColor,
                    Color.lerp(RiveAppTheme.accentColor, Colors.purple, 0.6)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: RiveAppTheme.accentColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Avatar with level badge
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Center(
                                child: Text(
                                  user.name.substring(0, 1),
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: RiveAppTheme.accentColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  "${user.level}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      
                      // User info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.local_fire_department, 
                                  color: Colors.orange, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  "${user.streak} day streak",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Progress to next level
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Level ${user.level}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "Level ${user.level + 1}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: user.xpPoints / 500, // Assuming 500 XP needed per level
                          minHeight: 10,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          "${user.xpPoints} / 500 XP",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Your Statistics",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RiveAppTheme.getTextColor(themeProvider.isDarkMode),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Stats cards
            SizedBox(
              height: 125,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildStatCard(
                    "Signs Mastered",
                    "${_additionalStats["signsMastered"]}",
                    Icons.verified,
                    Colors.green,
                    themeProvider,
                  ),
                  _buildStatCard(
                    "Practice Time",
                    "${(_additionalStats["totalPracticeTime"] / 60).round()} hrs",
                    Icons.access_time,
                    Colors.blue,
                    themeProvider,
                  ),
                  _buildStatCard(
                    "Member Since",
                    "${_formatJoinDate(_additionalStats["joinDate"])}",
                    Icons.calendar_today,
                    Colors.purple,
                    themeProvider,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Achievements section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Achievements",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: RiveAppTheme.getTextColor(themeProvider.isDarkMode),
                    ),
                  ),
                  Text(
                    "See All",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: RiveAppTheme.accentColor,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            ..._additionalStats["achievements"]
                .take(3)
                .map<Widget>((achievement) => _buildAchievementItem(achievement, themeProvider))
                .toList(),
            
            const SizedBox(height: 24),
            
            // Settings section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Quick Settings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RiveAppTheme.getTextColor(themeProvider.isDarkMode),
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            _buildSettingItem(
              "Notifications",
              "Receive app notifications",
              Icons.notifications_none,
              _notificationsEnabled,
              (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              themeProvider,
            ),
            
            _buildSettingItem(
              "Practice Reminders",
              "Daily reminders to practice",
              Icons.alarm,
              _practiceReminders,
              (value) {
                setState(() {
                  _practiceReminders = value;
                });
              },
              themeProvider,
            ),
            
            _buildSettingItem(
              "Data Synchronization",
              "Sync progress across devices",
              Icons.sync,
              _dataSync,
              (value) {
                setState(() {
                  _dataSync = value;
                });
              },
              themeProvider,
            ),
            
            _buildDarkModeSettingItem(themeProvider),
            
            const SizedBox(height: 20),
            
            // Account options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                color: RiveAppTheme.getCardColor(themeProvider.isDarkMode),
                child: Column(
                  children: [
                    _buildAccountOption(
                      "Edit Profile",
                      Icons.person_outline,
                      themeProvider: themeProvider,
                    ),
                    Divider(height: 1, color: RiveAppTheme.getDividerColor(themeProvider.isDarkMode)),
                    _buildAccountOption(
                      "Help & Support",
                      Icons.help_outline,
                      themeProvider: themeProvider,
                    ),
                    Divider(height: 1, color: RiveAppTheme.getDividerColor(themeProvider.isDarkMode)),
                    _buildAccountOption(
                      "Privacy Policy",
                      Icons.privacy_tip_outlined,
                      themeProvider: themeProvider,
                    ),
                    Divider(height: 1, color: RiveAppTheme.getDividerColor(themeProvider.isDarkMode)),
                    _buildAccountOption(
                      "Sign Out",
                      Icons.logout,
                      isDestructive: true,
                      themeProvider: themeProvider,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Version info
            Center(
              child: Text(
                "Version 1.0.0",
                style: TextStyle(
                  color: RiveAppTheme.getTextSecondaryColor(themeProvider.isDarkMode),
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeProvider themeProvider) {
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: RiveAppTheme.getCardColor(themeProvider.isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: RiveAppTheme.getTextColor(themeProvider.isDarkMode),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: RiveAppTheme.getTextSecondaryColor(themeProvider.isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAchievementItem(Map<String, dynamic> achievement, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RiveAppTheme.getCardColor(themeProvider.isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: achievement["unlocked"] 
                  ? Colors.amber.withOpacity(0.1)
                  : RiveAppTheme.getCardColor(themeProvider.isDarkMode).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.emoji_events,
                color: achievement["unlocked"] ? Colors.amber : RiveAppTheme.getTextSecondaryColor(themeProvider.isDarkMode),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement["name"],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: achievement["unlocked"] 
                        ? RiveAppTheme.getTextColor(themeProvider.isDarkMode) 
                        : RiveAppTheme.getTextSecondaryColor(themeProvider.isDarkMode),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  achievement["description"],
                  style: TextStyle(
                    fontSize: 12,
                    color: RiveAppTheme.getTextSecondaryColor(themeProvider.isDarkMode),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            achievement["unlocked"] ? Icons.check_circle : Icons.lock_outline,
            color: achievement["unlocked"] ? RiveAppTheme.successLight : RiveAppTheme.getTextSecondaryColor(themeProvider.isDarkMode),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSettingItem(String title, String description, IconData icon, bool value, Function(bool) onChanged, ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RiveAppTheme.getCardColor(themeProvider.isDarkMode),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RiveAppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: value ? RiveAppTheme.accentColor : Colors.grey[400],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: RiveAppTheme.accentColor,
            activeTrackColor: RiveAppTheme.accentColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDarkModeSettingItem(ThemeProvider themeProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RiveAppTheme.accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.dark_mode_outlined,
              color: themeProvider.isDarkMode ? RiveAppTheme.accentColor : Colors.grey[400],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dark Mode",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Switch to dark theme",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.setDarkMode(value);
            },
            activeColor: RiveAppTheme.accentColor,
            activeTrackColor: RiveAppTheme.accentColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountOption(String title, IconData icon, {bool isDestructive = false, ThemeProvider? themeProvider}) {
    final isDarkMode = themeProvider?.isDarkMode ?? false;
    
    return InkWell(
      onTap: () {
        // Handle option tap
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? RiveAppTheme.errorLight : RiveAppTheme.getTextSecondaryColor(isDarkMode),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDestructive ? RiveAppTheme.errorLight : RiveAppTheme.getTextColor(isDarkMode),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatJoinDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return "${months[date.month - 1]} ${date.year}";
  }
}