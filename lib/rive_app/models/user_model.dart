class UserModel {
  final int id;
  final String name;
  final String email;
  final String password; // In a real app, this should be hashed
  final int level;
  final int xpPoints;
  final int streak;
  final String avatar;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.level = 1,
    this.xpPoints = 0,
    this.streak = 0,
    this.avatar = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      level: json['level'] ?? 1,
      xpPoints: json['xp_points'] ?? 0,
      streak: json['streak'] ?? 0,
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'level': level,
      'xp_points': xpPoints,
      'streak': streak,
      'avatar': avatar,
    };
  }

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    int? level,
    int? xpPoints,
    int? streak,
    String? avatar,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      level: level ?? this.level,
      xpPoints: xpPoints ?? this.xpPoints,
      streak: streak ?? this.streak,
      avatar: avatar ?? this.avatar,
    );
  }
} 