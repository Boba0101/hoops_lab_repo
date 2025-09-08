import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String role; // 'Player' or 'Coach'
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool profileCompleted;

  // Profile fields (nullable)
  final String? name;
  final String? gender;
  final int? age;
  final double? weight; // kg
  final double? height; // cm
  final String? position; // Specific to Player role

  User({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
    this.profileCompleted = false,
    // Profile fields
    this.name,
    this.gender,
    this.age,
    this.weight,
    this.height,
    this.position,
  });

  // Convert to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'profileCompleted': profileCompleted,
      // Profile fields
      'name': name,
      'gender': gender,
      'age': age,
      'weight': weight,
      'height': height,
      'position': position,
    };
  }

  // Create from map (for Firebase)
  factory User.fromMap(Map<String, dynamic> map) {
    // Helper function to safely parse date fields that could be
    // either a Firestore Timestamp or an ISO8601 String.
    DateTime? _parseDate(dynamic dateValue) {
      if (dateValue == null) return null;
      if (dateValue is Timestamp) {
        // If it's a Timestamp, convert it to a DateTime.
        return dateValue.toDate();
      }
      if (dateValue is String) {
        // If it's a String, parse it.
        return DateTime.tryParse(dateValue);
      }
      return null;
    }

    return User(
      id: map['id'] ?? '',
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
  // Create a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? profileCompleted,
    String? name,
    String? gender,
    int? age,
    double? weight,
    double? height,
    String? position,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      position: position ?? this.position,
    );
  }
}
