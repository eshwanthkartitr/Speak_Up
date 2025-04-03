import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_samples/rive_app/theme.dart';

class ThemeProvider with ChangeNotifier {
  static const String _darkModeKey = 'isDarkMode';
  bool _isDarkMode = false;
  
  ThemeProvider() {
    _loadTheme();
  }
  
  // Getter for dark mode state
  bool get isDarkMode => _isDarkMode;
  
  // Getter for the current theme data
  ThemeData get themeData {
    if (_isDarkMode) {
      return ThemeData.dark().copyWith(
        primaryColor: RiveAppTheme.accentColorDark,
        scaffoldBackgroundColor: RiveAppTheme.getBackgroundColor(true),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: RiveAppTheme.accentColorDark,
          secondary: RiveAppTheme.accentColorDark,
          background: RiveAppTheme.getBackgroundColor(true),
          surface: RiveAppTheme.getCardColor(true),
          onBackground: RiveAppTheme.getTextColor(true),
          onSurface: RiveAppTheme.getTextColor(true),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: RiveAppTheme.background2Dark,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: RiveAppTheme.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          iconTheme: IconThemeData(
            color: RiveAppTheme.textDark,
          ),
        ),
        cardColor: RiveAppTheme.cardDark,
        canvasColor: RiveAppTheme.backgroundDark,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: RiveAppTheme.textDark),
          bodyMedium: TextStyle(color: RiveAppTheme.textDark),
          titleLarge: TextStyle(color: RiveAppTheme.textDark),
          titleMedium: TextStyle(color: RiveAppTheme.textDark),
          titleSmall: TextStyle(color: RiveAppTheme.textDark),
          labelLarge: TextStyle(color: RiveAppTheme.textDark),
        ),
        iconTheme: const IconThemeData(
          color: RiveAppTheme.textDark,
        ),
        dividerColor: Colors.white24,
        dialogBackgroundColor: RiveAppTheme.cardDark,
      );
    } else {
      return ThemeData.light().copyWith(
        primaryColor: RiveAppTheme.accentColor,
        scaffoldBackgroundColor: RiveAppTheme.getBackgroundColor(false),
        colorScheme: const ColorScheme.light().copyWith(
          primary: RiveAppTheme.accentColor,
          secondary: RiveAppTheme.accentColor,
          background: RiveAppTheme.getBackgroundColor(false),
          surface: RiveAppTheme.getCardColor(false),
          onBackground: RiveAppTheme.getTextColor(false),
          onSurface: RiveAppTheme.getTextColor(false),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: RiveAppTheme.textLight,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          iconTheme: IconThemeData(
            color: RiveAppTheme.textLight,
          ),
        ),
        cardColor: Colors.white,
        canvasColor: RiveAppTheme.background,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: RiveAppTheme.textLight),
          bodyMedium: TextStyle(color: RiveAppTheme.textLight),
          titleLarge: TextStyle(color: RiveAppTheme.textLight),
          titleMedium: TextStyle(color: RiveAppTheme.textLight),
          titleSmall: TextStyle(color: RiveAppTheme.textLight),
          labelLarge: TextStyle(color: RiveAppTheme.textLight),
        ),
        iconTheme: const IconThemeData(
          color: RiveAppTheme.textLight,
        ),
        dividerColor: Colors.black12,
        dialogBackgroundColor: Colors.white,
      );
    }
  }
  
  // Load theme preference from shared preferences
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
      notifyListeners();
    } catch (e) {
      // Default to light mode if there's an error
      _isDarkMode = false;
      notifyListeners();
    }
  }
  
  // Toggle theme and save preference
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
    } catch (e) {
      // Ignore errors with saving preference
    }
    
    notifyListeners();
  }
  
  // Set specific theme state and save preference
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_darkModeKey, _isDarkMode);
      } catch (e) {
        // Ignore errors with saving preference
      }
      
      notifyListeners();
    }
  }
} 