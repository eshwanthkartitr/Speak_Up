import 'package:flutter/material.dart';
import 'package:flutter_samples/rive_app/models/user_model.dart';
import 'package:mongo_dart/mongo_dart.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool _isInitialized = false;
  bool _useMockData = false;
  late Db _db;
  late DbCollection _usersCollection;

  // Mock users data for fallback
  final List<UserModel> _mockUsers = [
    
  ];

  // MongoDB connection string
  // Using environment variable or secure configuration
  final String _connectionString = 'private_uri';

  // Initialize the database service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('Attempting to connect to MongoDB...');
      // Connect to MongoDB
      _db = await Db.create(_connectionString);
      await _db.open();
      _usersCollection = _db.collection('users'); // Changed collection name to be more specific
      _isInitialized = true;
      _useMockData = false;
      print('MongoDB database initialized successfully');
    } catch (e) {
      print('Failed to initialize MongoDB: $e');
      _useMockData = true;
      print('Falling back to mock data');
    }
  }

  // Authenticate user - returns user if valid, null otherwise
  Future<UserModel?> authenticateUser(String email, String password) async {
    if (!_isInitialized && !_useMockData) await initialize();
    
    try {
      if (_useMockData) {
        print('Using mock data for authentication');
        return _mockUsers.firstWhere(
          (u) => u.email == email && u.password == password,
          orElse: () => throw 'Invalid credentials'
        );
      } else {
        // Use MongoDB with proper error handling
        final Map<String, dynamic>? userData = await _usersCollection.findOne(
          where.eq('email', email).eq('password', password)
        );
        
        if (userData != null) {
          final user = UserModel.fromJson(userData);
          print('Authentication successful for: ${user.name}');
          return user;
        }
        
        print('Authentication failed: Invalid credentials');
        return null;
      }
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    if (!_isInitialized && !_useMockData) await initialize();
    
    try {
      if (_useMockData) {
        // Use mock data
        try {
          final user = _mockUsers.firstWhere((u) => u.email == email);
          return user;
        } catch (e) {
          return null;
        }
      } else {
        final Map<String, dynamic>? userData = await _usersCollection.findOne(
          where.eq('email', email)
        );
        
        if (userData != null) {
          return UserModel.fromJson(userData);
        }
        return null;
      }
    } catch (e) {
      print('Error getting user by email: $e');
      
      // If MongoDB throws an error, try with mock data
      if (!_useMockData) {
        _useMockData = true;
        return getUserByEmail(email);
      }
      
      return null;
    }
  }

  // Update user
  Future<UserModel?> updateUser(UserModel user) async {
    if (!_isInitialized && !_useMockData) await initialize();
    
    try {
      if (_useMockData) {
        // Update in mock data
        final index = _mockUsers.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _mockUsers[index] = user;
          return user;
        }
        return null;
      } else {
        await _usersCollection.update(
          where.eq('_id', user.id),
          user.toJson()
        );
        return user;
      }
    } catch (e) {
      print('Error updating user: $e');
      
      // If MongoDB throws an error, try with mock data
      if (!_useMockData) {
        _useMockData = true;
        return updateUser(user);
      }
      
      return null;
    }
  }
}

Future<void> login(String email, String password) async {
  try {
    print('Login attempt: email=$email, password=$password');
    final databaseService = DatabaseService();
    final user = await databaseService.authenticateUser(email, password);
    
    if (user != null) {
      // Login successful, update your app state
      print('Login successful for: ${user.name}');
      // Navigate to home screen or update provider
    } else {
      // Show error message for invalid credentials
      print('Invalid credentials');
    }
  } catch (e) {
    print('Login error: $e');
    // Show generic error message
  }
}