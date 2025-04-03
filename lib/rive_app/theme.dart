import 'package:flutter/material.dart';

class RiveAppTheme {
  // Primary and accent colors
  static const Color accentColor = Color(0xFF5E9EFF);
  static const Color accentColorDark = Color(0xFF78ABFF);
  static const Color secondaryAccent = Color(0xFF7B61FF);
  static const Color secondaryAccentDark = Color(0xFF9980FF);
  
  // Shadow colors
  static const Color shadow = Color(0xFF4A5367);
  static const Color shadowDark = Color(0xFF000000);
  
  // Background colors
  static const Color background = Color(0xFFF2F6FF);  // Light blue background for light mode
  static const Color backgroundDark = Color(0xFF0F1729);  // Darker blue for dark mode
  static const Color background2 = Color(0xFF17203A);
  static const Color background2Dark = Color(0xFF0A101F);
  
  // Card colors
  static const Color cardLight = Colors.white;
  static const Color cardDark = Color(0xFF1D2B45);
  
  // Text colors
  static const Color textLight = Color(0xFF1E1E1E);
  static const Color textDark = Color(0xFFF0F0F0);
  static const Color textSecondaryLight = Color(0xFF6B6B6B);
  static const Color textSecondaryDark = Color(0xFFADADAD);
  
  // Input field colors
  static const Color inputBackgroundLight = Colors.white;
  static const Color inputBackgroundDark = Color(0xFF1D2B45);
  static const Color inputBorderLight = Color(0xFFE0E0E0);
  static const Color inputBorderDark = Color(0xFF2C3B52);
  
  // Success, warning, error colors
  static const Color successLight = Color(0xFF4CAF50);
  static const Color successDark = Color(0xFF66BB6A);
  static const Color warningLight = Color(0xFFFFC107);
  static const Color warningDark = Color(0xFFFFD54F);
  static const Color errorLight = Color(0xFFF44336);
  static const Color errorDark = Color(0xFFE57373);
  
  // Button colors
  static const Color buttonLight = accentColor;
  static const Color buttonDark = accentColorDark;
  static const Color buttonTextLight = Colors.white;
  static const Color buttonTextDark = Colors.white;
  
  // Divider colors
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF2C3B52);
  
  // Onboarding specific colors - always keep light
  static const Color onboardingBackground = Colors.white;
  static const Color onboardingText = Color(0xFF1E1E1E);
  
  // Get color based on dark mode
  static Color getColor(bool isDarkMode, Color lightColor, Color darkColor) {
    return isDarkMode ? darkColor : lightColor;
  }
  
  // Get app background color
  static Color getBackgroundColor(bool isDarkMode) {
    return isDarkMode ? backgroundDark : background;
  }
  
  // Get card background color
  static Color getCardColor(bool isDarkMode) {
    return isDarkMode ? cardDark : cardLight;
  }
  
  // Get text color
  static Color getTextColor(bool isDarkMode) {
    return isDarkMode ? textDark : textLight;
  }
  
  // Get secondary text color
  static Color getTextSecondaryColor(bool isDarkMode) {
    return isDarkMode ? textSecondaryDark : textSecondaryLight;
  }
  
  // Get button color
  static Color getButtonColor(bool isDarkMode) {
    return isDarkMode ? buttonDark : buttonLight;
  }
  
  // Get button text color
  static Color getButtonTextColor(bool isDarkMode) {
    return isDarkMode ? buttonTextDark : buttonTextLight;
  }
  
  // Get divider color
  static Color getDividerColor(bool isDarkMode) {
    return isDarkMode ? dividerDark : dividerLight;
  }
  
  // Get input background color
  static Color getInputBackgroundColor(bool isDarkMode) {
    return isDarkMode ? inputBackgroundDark : inputBackgroundLight;
  }
  
  // Get input border color
  static Color getInputBorderColor(bool isDarkMode) {
    return isDarkMode ? inputBorderDark : inputBorderLight;
  }
}