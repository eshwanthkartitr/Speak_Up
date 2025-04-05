import 'package:flutter_samples/rive_app/models/user_model.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  bool _isInitialized = false;

  // Mock data for users
  final List<UserModel> _mockUsers = [
    UserModel(
      id: 1, 
      name: 'Eshwanth Karti T R', 
      email: 'eshwanthkartitr@gmail.com', 
      password: 'Tr3102',
      level: 5,
      xpPoints: 450,
      streak: 7,
      avatar: 'assets/rive_app/images/avatars/avatar1.png',
    ),
    UserModel(
      id: 2, 
      name: 'John Doe', 
      email: 'john@example.com', 
      password: 'password123',
      level: 3,
      xpPoints: 280,
      streak: 5,
      avatar: 'assets/rive_app/images/avatars/avatar2.png',
    ),
    UserModel(
      id: 3, 
      name: 'Jane Smith', 
      email: 'jane@example.com', 
      password: 'securepass',
      level: 7,
      xpPoints: 850,
      streak: 14,
      avatar: 'assets/rive_app/images/avatars/avatar3.png',
    ),
    UserModel(
      id: 4, 
      name: 'Alice Johnson', 
      email: 'alice@example.com', 
      password: 'alice2024',
      level: 2,
      xpPoints: 120,
      streak: 2,
      avatar: 'assets/rive_app/images/avatars/avatar4.png',
    ),
    UserModel(
      id: 5, 
      name: 'Bob Williams', 
      email: 'bob@example.com', 
      password: 'bobpass',
      level: 4,
      xpPoints: 320,
      streak: 3,
      avatar: 'assets/rive_app/images/avatars/avatar5.png',
    ),
  ];

  // Initialize the database service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;
    print('Mock database initialized successfully');
  }

  // Authenticate user - returns user if valid, null otherwise
  Future<UserModel?> authenticateUser(String email, String password) async {
    if (!_isInitialized) await initialize();
    
    print('Authenticating user: $email with password: $password');
    print('Available users:');
    for (var user in _mockUsers) {
      print('- ${user.email} / ${user.password}');
    }
    
    try {
      // Find the user with matching email and password
      final user = _mockUsers.firstWhere(
        (user) => user.email == email && user.password == password,
      );
      print('Authentication successful for: ${user.name}');
      return user;
    } catch (e) {
      // User not found
      print('Authentication failed: Invalid credentials - $e');
      return null;
    }
  }

  // Get user by email
  Future<UserModel?> getUserByEmail(String email) async {
    if (!_isInitialized) await initialize();
    
    try {
      return _mockUsers.firstWhere((user) => user.email == email);
    } catch (_) {
      return null;
    }
  }

  // Update user
  Future<UserModel?> updateUser(UserModel user) async {
    if (!_isInitialized) await initialize();
    
    final index = _mockUsers.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _mockUsers[index] = user;
      return user;
    }
    
    return null;
  }
} 