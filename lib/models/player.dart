// class Player {
//   final String id;
//   final String name;
//   final double points;
//   final double rebounds;
//   final double assists;
//   final double fgPercentage;
//   final String? imageUrl; // For Firebase storage
//   final String? imagePath; // For local file path
//   final List<FatigueData>? fatigueHistory;

//   @override
//   bool operator ==(Object other) => // compare Player objects by ID.
//       identical(this, other) ||
//       other is Player && runtimeType == other.runtimeType && id == other.id;

//   @override
//   int get hashCode => id.hashCode;

//   Player({
//     required this.id,
//     required this.name,
//     required this.points,
//     required this.rebounds,
//     required this.assists,
//     required this.fgPercentage,
//     this.imageUrl,
//     this.imagePath,
//     this.fatigueHistory,
//   });

//   // Convert to map for Firebase
//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'name': name,
//       'points': points,
//       'rebounds': rebounds,
//       'assists': assists,
//       'fgPercentage': fgPercentage,
//       'imageUrl': imageUrl,
//       'fatigueHistory': fatigueHistory?.map((f) => f.toMap()).toList(),
//     };
//   }

//   // Create from map (for Firebase)
//   factory Player.fromMap(Map<String, dynamic> map) {
//     return Player(
//       id: map['id'],
//       name: map['name'],
//       points: (map['points'] is int)
//           ? (map['points'] as int).toDouble()
//           : (map['points'] as double),
//       rebounds: (map['rebounds'] is int)
//           ? (map['rebounds'] as int).toDouble()
//           : (map['rebounds'] as double),
//       assists: (map['assists'] is int)
//           ? (map['assists'] as int).toDouble()
//           : (map['assists'] as double),
//       fgPercentage: (map['fgPercentage'] is int)
//           ? (map['fgPercentage'] as int).toDouble()
//           : (map['fgPercentage'] as double),
//       imageUrl: map['imageUrl'],
//       fatigueHistory: map['fatigueHistory'] != null
//           ? (map['fatigueHistory'] as List)
//               .map((f) => FatigueData.fromMap(f as Map<String, dynamic>))
//               .toList()
//           : null,
//     );
//   }
// }

// class FatigueData {
//   final DateTime date;
//   final int fatigueLevel; // 1-10 scale
//   final int minutesPlayed;
//   final String? notes;

//   FatigueData({
//     required this.date,
//     required this.fatigueLevel,
//     required this.minutesPlayed,
//     this.notes,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'date': date.toIso8601String(),
//       'fatigueLevel': fatigueLevel,
//       'minutesPlayed': minutesPlayed,
//       'notes': notes,
//     };
//   }

//   factory FatigueData.fromMap(Map<String, dynamic> map) {
//     return FatigueData(
//       date: DateTime.parse(map['date']),
//       fatigueLevel: map['fatigueLevel'],
//       minutesPlayed: map['minutesPlayed'],
//       notes: map['notes'],
//     );
//   }
// }
class Player {
  final String id;
  final String name;
  final double height; // Height in cm
  final double weight; // Weight in kg
  final int age; // Age in years
  final String team; // Team name
  final String position; // Player position
  final String? imageBase64; // Base64-encoded image

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Player && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  Player({
    required this.id,
    required this.name,
    required this.height,
    required this.weight,
    required this.age,
    required this.team,
    required this.position,
    this.imageBase64,
  });

  // Convert to map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'height': height,
      'weight': weight,
      'age': age,
      'team': team,
      'position': position,
      'imageBase64': imageBase64,
    };
  }

  // Create from map (for Firebase)
  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'],
      name: map['name'],
      height: (map['height'] is int)
          ? (map['height'] as int).toDouble()
          : (map['height'] as double),
      weight: (map['weight'] is int)
          ? (map['weight'] as int).toDouble()
          : (map['weight'] as double),
      age: map['age'],
      team: map['team'],
      position: map['position'],
      imageBase64: map['imageBase64'],
    );
  }
}
