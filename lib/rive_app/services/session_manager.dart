import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  // Singleton pattern
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  // Constants
  static const String _lastActivityKey = 'last_activity_time';
  static const String _userEmailKey = 'user_email';
  static const String _userPasswordKey = 'user_password';
  static const Duration _sessionTimeout = Duration(minutes: 30);

  // Secure storage for sensitive data
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Timer for session expiry check
  Timer? _sessionTimer;

  // Initialize the session manager
  Future<void> initialize() async {
    // Start monitoring session
    _startSessionMonitoring();
  }

  // Start the session timer
  void _startSessionMonitoring() {
    // Cancel any existing timer
    _sessionTimer?.cancel();
    
    // Check session validity every minute
    _sessionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      checkSessionValidity();
    });
  }

  // Record user activity
  Future<void> recordActivity() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastActivityKey, now);
  }

  // Check if session is still valid
  Future<bool> checkSessionValidity() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivity = prefs.getInt(_lastActivityKey);
    
    if (lastActivity == null) {
      return false; // No session exists
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = now - lastActivity;
    
    // If more than 30 minutes have passed since last activity
    if (difference > _sessionTimeout.inMilliseconds) {
      await clearSession(); // Clear session data
      return false;
    }
    
    return true; // Session is still valid
  }

  // Save user credentials securely (only saved when user explicitly logs in)
  Future<void> saveCredentials(String email, String password) async {
    await _secureStorage.write(key: _userEmailKey, value: email);
    await _secureStorage.write(key: _userPasswordKey, value: password);
    await recordActivity(); // Record login activity
  }

  // Get saved credentials
  Future<Map<String, String?>> getSavedCredentials() async {
    final email = await _secureStorage.read(key: _userEmailKey);
    final password = await _secureStorage.read(key: _userPasswordKey);
    
    return {
      'email': email,
      'password': password,
    };
  }

  // Clear session data
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActivityKey);
    
    // Note: We keep the credentials for future auto-login
    // To clear credentials on explicit logout, call clearCredentials()
  }

  // Clear credentials (use on explicit logout)
  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _userEmailKey);
    await _secureStorage.delete(key: _userPasswordKey);
    await clearSession();
  }

  // Dispose resources
  void dispose() {
    _sessionTimer?.cancel();
  }
}