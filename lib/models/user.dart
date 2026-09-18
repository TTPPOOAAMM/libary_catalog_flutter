import '../core/permissions.dart';

class User {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final UserRole role;

  const User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
  });

  User copyWith({
    int? id,
    String? username,
    String? fullName,
    String? email,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'fullName': fullName,
        'email': email,
        'role': role.code,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      fullName:
          json['fullName'] as String? ?? json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
    );
  }
}
