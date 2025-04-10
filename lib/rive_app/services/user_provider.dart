import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/models/user_model.dart';
import 'package:flutter_samples/rive_app/services/database_service.dart';
import 'package:flutter_samples/rive_app/services/session_manager.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  String? _error;
  final DatabaseService _databaseService = DatabaseService();
  final SessionManager _sessionManager = SessionManager();

  // Getter for error
  String? get error => _error;

  UserProvider() {
    // Initialize session monitoring
    _sessionManager.initialize();
    
    // Try to auto-login using saved credentials
    autoLogin();
  }

  // Initialize method
  Future<void> initialize() async {
    await autoLogin();
    notifyListeners();
  }

  // Getter for current user
  UserModel? get currentUser => _currentUser;
  
  // Getter for authentication status
  bool get isAuthenticated => _isAuthenticated;

  // Auto-login using saved credentials
  Future<bool> autoLogin() async {
    try {
      // Check if session is still valid
      final isSessionValid = await _sessionManager.checkSessionValidity();
      
      // If session is valid, try to get saved credentials
      if (isSessionValid) {
        final credentials = await _sessionManager.getSavedCredentials();
        final email = credentials['email'];
        final password = credentials['password'];
        
        // If we have credentials, try to log in
        if (email != null && password != null) {
          final success = await login(email, password, rememberMe: false);
          return success;
        }
      }
      return false;
    } catch (e) {
      print('Auto-login failed: $e');
      return false;
    }
  }

  // Login method
  Future<bool> login(String email, String password, {bool rememberMe = true}) async {
    try {
      print('Calling databaseService.authenticateUser');
      final user = await _databaseService.authenticateUser(email, password);
      
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        
        // Record activity to start the session
        await _sessionManager.recordActivity();
        
        // Save credentials if rememberMe is true
        if (rememberMe) {
          await _sessionManager.saveCredentials(email, password);
        }
        
        notifyListeners();
        print('Login result: true');
        return true;
      } else {
        _isAuthenticated = false;
        notifyListeners();
        print('Login result: false');
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      _isAuthenticated = false;
      notifyListeners();
      return false;
    }
  }

  // Logout method
  Future<void> logout({bool clearCredentials = true}) async {
    _currentUser = null;
    _isAuthenticated = false;
    
    // If we should clear credentials (explicit logout)
    if (clearCredentials) {
      await _sessionManager.clearCredentials();
    } else {
      // Just clear the session but keep credentials for auto-login
      await _sessionManager.clearSession();
    }
    
    notifyListeners();
  }

  // Record user activity - call this in key parts of the app
  Future<void> recordActivity() async {
    if (_isAuthenticated) {
      await _sessionManager.recordActivity();
    }
  }
  
  // Update user profile
  Future<bool> updateUserProfile(UserModel updatedUser) async {
    try {
      final result = await _databaseService.updateUser(updatedUser);
      
      if (result != null) {
        _currentUser = result;
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }
}