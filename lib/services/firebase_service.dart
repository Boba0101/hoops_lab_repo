// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart'; // We only need the User model now
import '../firebase_options.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase Firestore instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get usersCollection => _db.collection('users');

  // Initialize Firebase
  static Future<void> initialize() async {
    try {
      // THIS IS THE SAFETY CHECK. It prevents the duplicate app error.
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        print('Firebase initialized successfully');
      } else {
        print('Firebase already initialized, skipping...');
      }
      FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      print('Firestore persistence enabled');
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  // --- NEW UNIFIED METHODS ---

  // Save or update a user document (typically on sign-up)
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

  // Get a single user by ID
  Future<User?> getUserById(String id) async {
    try {
      DocumentSnapshot doc = await usersCollection.doc(id).get();
      if (doc.exists && doc.data() is Map<String, dynamic>) {
        return User.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('ERROR in getUserById: $e');
      rethrow;
    }
    return null;
  }

  // NEW: Get a stream of all players for the coach's dashboard
  Stream<List<User>> getPlayersStream() {
    return usersCollection
        .where('role', isEqualTo: 'Player')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return User.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    }).handleError((error) {
      print("Error fetching players stream: $error");
      return [];
    });
  }

  // NEW: Update a user's profile information and mark as complete
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> data) async {
    try {
      // We add profileCompleted: true to every profile update.
      final updateData = {...data, 'profileCompleted': true};
      await usersCollection.doc(userId).update(updateData);
      print('Profile updated successfully for user: $userId');
    } catch (e) {
      print('ERROR updating user profile: $e');
      rethrow;
    }
  }

  // Update user's last login time
  Future<void> updateLastLogin(String userId) async {
    await usersCollection.doc(userId).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }
}
