class Player {
  final String id;
  final String name;
  final double height; // Height in cm
  final double weight; // Weight in kg
  final int age; // Age in years
  final String team; // Team name
  final String position; // Player position
  final String? imageBase64; // Base64-encoded image
  final String? userId; // Link to User account (optional for existing players)

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
    this.userId,
  });

  // Empty constructor for error handling
  Player.empty()
      : id = '',
        name = '',
        height = 0.0,
        weight = 0.0,
        age = 0,
        team = '',
        position = '',
        imageBase64 = null,
        userId = null;

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
      'userId': userId,
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
      userId: map['userId'], // Handle existing players without userId
    );
  }
}
