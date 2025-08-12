import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'; // Added for kDebugMode
import '../models/player.dart';
import '../models/user.dart';
import '../firebase_options.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase Firestore instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get playersCollection => _db.collection('players');
  CollectionReference get usersCollection => _db.collection('users');

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase initialized successfully');
      } else {
        print('Firebase already initialized, skipping...');
      }

      // Enable persistence explicitly
      FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      print('Firestore persistence enabled');

      // Only run tests in debug mode
      if (kDebugMode) {
        try {
          // Test Firestore connection
          await FirebaseFirestore.instance.collection('test').doc('test').get();
          print('Firestore connection test successful');

          // Test write permissions
          final firebaseService = FirebaseService();
          await firebaseService.testFirestoreWrite();

          // Test user creation
          await firebaseService.testUserCreation();
        } catch (e) {
          print('Firestore connection test failed: $e');
        }
      }
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  // Add or update a player
  Future<void> savePlayer(Player player) async {
    await playersCollection.doc(player.id).set(player.toMap());
  }

  // Get all players
  Stream<List<Player>> getPlayers() {
    return playersCollection.snapshots().handleError((error) {
      print('Firestore players stream error: $error');
      // Return empty list on error to keep stream alive
      return [];
    }).map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Player.fromMap(doc.data() as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing player document ${doc.id}: $e');
          return Player.empty(); // Add this method to your Player model
        }
      }).toList();
    });
  }

  // Get a single player by ID
  Future<Player?> getPlayerById(String id) async {
    DocumentSnapshot doc = await playersCollection.doc(id).get();
    if (doc.exists) {
      return Player.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Delete a player
  Future<void> deletePlayer(String id) async {
    await playersCollection.doc(id).delete();
  }

  // User management methods
  // Save or update a user
  Future<void> saveUser(User user) async {
    print('FirebaseService.saveUser called with user: ${user.toMap()}');
    try {
      await usersCollection.doc(user.id).set(user.toMap());
      print('User data successfully written to Firestore');
    } catch (e) {
      print('ERROR saving user to Firestore: $e');
      rethrow;
    }
  }

  // IMPROVED: Safe type handling for Firestore documents
  Future<User?> getUserById(String id) async {
    DocumentSnapshot doc = await usersCollection.doc(id).get();
    if (doc.exists) {
      final data = doc.data();

      // Handle both map and list responses safely
      if (data is Map<String, dynamic>) {
        return User.fromMap(data);
      }
      // Add special handling for list responses
      else if (data is List) {
        // Convert first list element if it's a map
        if (data.isNotEmpty && data[0] is Map<String, dynamic>) {
          return User.fromMap(data[0] as Map<String, dynamic>);
        }
      }

      print('Unexpected document data type: ${data.runtimeType}');
    }
    return null;
  }

  // Update user's last login time
  Future<void> updateLastLogin(String userId) async {
    await usersCollection.doc(userId).update({
      'lastLoginAt': DateTime.now().toIso8601String(),
    });
  }

  // DEBUG ONLY: Test method for user retrieval
  Future<void> testUserRetrieval(String userId) async {
    // Only run in debug mode
    if (!kDebugMode) return;

    try {
      final user = await getUserById(userId);
      if (user != null) {
        print('[DEBUG] User retrieved: ${user.toMap()}');
      } else {
        print('[DEBUG] No user found with ID: $userId');
      }
    } catch (e) {
      print('[DEBUG] Error retrieving user: $e');
    }
  }

  // DEBUG ONLY: Test Firestore write permissions
  Future<void> testFirestoreWrite() async {
    if (!kDebugMode) return;

    try {
      print('[DEBUG] Testing Firestore write permissions...');
      await _db.collection('test').doc('write-test').set({
        'timestamp': DateTime.now().toIso8601String(),
        'test': true,
      });
      print('[DEBUG] Firestore write test successful');

      // Clean up test document
      await _db.collection('test').doc('write-test').delete();
      print('[DEBUG] Test document cleaned up');
    } catch (e) {
      print('[DEBUG] Firestore write test failed: $e');
    }
  }

  // DEBUG ONLY: Test user creation
  Future<void> testUserCreation() async {
    if (!kDebugMode) return;

    try {
      print('[DEBUG] Testing user creation...');
      final testUser = User(
        id: 'test-user-${DateTime.now().millisecondsSinceEpoch}',
        email: 'test@example.com',
        role: 'Player',
        createdAt: DateTime.now(),
      );

      await saveUser(testUser);
      print('[DEBUG] Test user created successfully');

      // Test retrieval
      final retrievedUser = await getUserById(testUser.id);
      if (retrievedUser != null) {
        print('[DEBUG] Test user retrieved: ${retrievedUser.toMap()}');
      } else {
        print('[DEBUG] Failed to retrieve test user');
      }

      // Clean up
      await usersCollection.doc(testUser.id).delete();
      print('[DEBUG] Test user cleaned up');
    } catch (e) {
      print('[DEBUG] Test user creation failed: $e');
    }
  }
}
