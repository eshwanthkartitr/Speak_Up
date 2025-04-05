import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/models/user_model.dart';
import 'package:flutter_samples/rive_app/services/database_service.dart';

class UserProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  // Initialize the database service
  Future<void> initialize() async {
    await _databaseService.initialize();
  }

  // Login with email and password
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _databaseService.authenticateUser(email, password);
      
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        _error = null;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _error = 'Invalid email or password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Logout current user
  void logout() {
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  // Update user stats
  Future<void> updateUserStats({int? level, int? xpPoints, int? streak}) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      level: level ?? _currentUser!.level,
      xpPoints: xpPoints ?? _currentUser!.xpPoints,
      streak: streak ?? _currentUser!.streak,
    );

    final result = await _databaseService.updateUser(updatedUser);
    
    if (result != null) {
      _currentUser = result;
      notifyListeners();
    }
  }

  // Get user information
  Future<void> fetchUserInfo(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _databaseService.getUserByEmail(email);
      
      if (user != null) {
        _currentUser = user;
        _error = null;
      } else {
        _error = 'User not found';
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
} 