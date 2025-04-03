import 'package:shared_preferences/shared_preferences.dart';

class OnboardingUtils {
  static const String _hasSeenOnboardingKey = 'hasSeenOnboarding';

  // Check if user has seen onboarding
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenOnboardingKey) ?? false;
  }

  // Mark onboarding as seen
  static Future<void> setOnboardingAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, true);
  }

  // Reset onboarding state (for testing)
  static Future<void> resetOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenOnboardingKey, false);
  }
} 