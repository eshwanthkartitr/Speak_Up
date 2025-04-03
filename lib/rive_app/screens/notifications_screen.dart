import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/theme.dart';
import 'package:flutter_samples/rive_app/theme_provider.dart';
import 'package:provider/provider.dart';

enum NotificationType {
  lesson,
  achievement,
  reminder,
  update,
}

class NotificationItem {
  final String title;
  final String message;
  final DateTime time;
  bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      title: 'New Lesson Available',
      message: 'Check out the new advanced greetings lesson!',
      time: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: false,
      type: NotificationType.lesson,
    ),
    NotificationItem(
      title: 'Achievement Unlocked',
      message: 'You\'ve earned the "7 Day Streak" badge! Keep it up!',
      time: DateTime.now().subtract(const Duration(hours: 3)),
      isRead: false,
      type: NotificationType.achievement,
    ),
    NotificationItem(
      title: 'Practice Reminder',
      message: 'It\'s been 2 days since your last practice session.',
      time: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.reminder,
    ),
    NotificationItem(
      title: 'New Feature',
      message: 'We\'ve added a new hand tracking feature for better feedback.',
      time: DateTime.now().subtract(const Duration(days: 3)),
      isRead: true,
      type: NotificationType.update,
    ),
  ];

  void _toggleReadStatus(int index) {
    setState(() {
      _notifications[index].isRead = !_notifications[index].isRead;
    });
  }

  void _clearAllNotifications() {
    setState(() {
      _notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get safe area to avoid system UI overlaps
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    
    // Get theme provider to access dark mode state
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Container(
      color: RiveAppTheme.getBackgroundColor(isDarkMode),
      child: Column(
        children: [
          // Add extra padding at the top to avoid menu button overlap
          SizedBox(height: topPadding + 60),
          
          // Custom app bar that doesn't conflict with home.dart elements
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: RiveAppTheme.getTextColor(isDarkMode)
                  ),
                ),
                TextButton(
                  onPressed: _clearAllNotifications,
                  child: Text(
                    'Clear All',
                    style: TextStyle(color: RiveAppTheme.accentColor),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Content area
          Expanded(
            child: _notifications.isEmpty
                ? _buildEmptyState(isDarkMode)
                : _buildNotificationsList(isDarkMode),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined, 
            size: 80, 
            color: RiveAppTheme.getTextSecondaryColor(isDarkMode).withOpacity(0.3)
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18, 
              color: RiveAppTheme.getTextColor(isDarkMode)
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: TextStyle(
              fontSize: 14, 
              color: RiveAppTheme.getTextSecondaryColor(isDarkMode)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(bool isDarkMode) {
    return ListView.builder(
      itemCount: _notifications.length,
      // Increase bottom padding to avoid tab bar overlap
      padding: const EdgeInsets.only(bottom: 100),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Dismissible(
          key: Key(notification.title + index.toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red.shade400,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          onDismissed: (direction) {
            setState(() {
              _notifications.removeAt(index);
            });
          },
          child: Card(
            // Make cards more compact with less vertical spacing
            margin: const EdgeInsets.fromLTRB(16, 3, 16, 3),
            elevation: notification.isRead ? 0 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: notification.isRead 
                    ? Colors.transparent
                    : RiveAppTheme.accentColor.withOpacity(0.3),
                width: notification.isRead ? 0 : 1,
              ),
            ),
            color: notification.isRead 
                ? RiveAppTheme.getCardColor(isDarkMode)
                : RiveAppTheme.accentColor.withOpacity(isDarkMode ? 0.15 : 0.03),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _toggleReadStatus(index),
              child: Padding(
                // Further reduce padding to make items more compact
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildNotificationIcon(notification.type),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  notification.title,
                                  style: TextStyle(
                                    fontWeight: notification.isRead 
                                        ? FontWeight.normal 
                                        : FontWeight.bold,
                                    fontSize: 14,
                                    color: RiveAppTheme.getTextColor(isDarkMode),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatTime(notification.time),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification.message,
                            style: TextStyle(
                              fontSize: 12,
                              color: RiveAppTheme.getTextSecondaryColor(isDarkMode),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: RiveAppTheme.accentColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationIcon(NotificationType type) {
    IconData iconData;
    Color iconColor;
    
    switch (type) {
      case NotificationType.lesson:
        iconData = Icons.menu_book;
        iconColor = Colors.blue;
        break;
      case NotificationType.achievement:
        iconData = Icons.emoji_events;
        iconColor = Colors.amber;
        break;
      case NotificationType.reminder:
        iconData = Icons.alarm;
        iconColor = Colors.orange;
        break;
      case NotificationType.update:
        iconData = Icons.system_update;
        iconColor = Colors.green;
        break;
    }
    
    // Make icons smaller to reduce visual noise
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 16, color: iconColor),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}