// lib/models/user.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String userId; // Standardized field name
  final String email, role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool profileCompleted;
  final String? name, gender, position;
  final int? age;
  final double? weight, height;

  User(
      {required this.userId,
      required this.email,
      required this.role,
      required this.createdAt,
      this.lastLoginAt,
      this.profileCompleted = false,
      this.name,
      this.gender,
      this.age,
      this.weight,
      this.height,
      this.position});

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'email': email,
        'role': role,
        'createdAt': createdAt.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'profileCompleted': profileCompleted,
        'name': name,
        'gender': gender,
        'age': age,
        'weight': weight,
        'height': height,
        'position': position
      };

  factory User.fromMap(Map<String, dynamic> map) {
    DateTime? _parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is Timestamp) return dateValue.toDate();
      if (dateValue is String) return DateTime.tryParse(dateValue);
      return null;
    }

    return User(
      userId: map['userId'] ?? map['id'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'Player',
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      lastLoginAt: _parseDate(map['lastLoginAt']),
      profileCompleted: map['profileCompleted'] ?? false,
      name: map['name'],
      gender: map['gender'],
      age: map['age'],
      weight: (map['weight'] as num?)?.toDouble(),
      height: (map['height'] as num?)?.toDouble(),
      position: map['position'],
    );
  }
}
