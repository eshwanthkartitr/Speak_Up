class UserModel {
  final int id;
  final String name;
  final String email;
  final String password;
  final int level;
  final int xpPoints;
  final int streak;
  final String avatar;
  final String? permissionLevel;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.level,
    required this.xpPoints,
    required this.streak,
    required this.avatar,
    this.permissionLevel,
  });

  // Add copyWith method to create a new instance with some properties changed
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    int? level,
    int? xpPoints,
    int? streak,
    String? avatar,
    String? permissionLevel,
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
      permissionLevel: permissionLevel ?? this.permissionLevel,
    );
  }

  // Convert from MongoDB document to UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] is int ? json['_id'] : int.parse(json['_id'].toString()),
      name: json['name'],
      email: json['email'],
      password: json['password'],
      level: json['level'],
      xpPoints: json['xpPoints'],
      streak: json['streak'],
      avatar: json['avatar'],
      permissionLevel: json['permission_level'],
    );
  }

  // Convert to JSON for MongoDB
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'password': password,
      'level': level,
      'xpPoints': xpPoints,
      'streak': streak,
      'avatar': avatar,
      'permission_level': permissionLevel,
    };
  }
}