// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/game_stats.dart';
import '../models/live_game.dart';
import '../models/user.dart';
import '../models/event_with_stats_status.dart';
import '../screens/schedule_screen.dart' as app_event;
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
  // Collection reference for game stats
  CollectionReference get gameStatsCollection => _db.collection('game_stats');
  // Collection reference for live games
  CollectionReference get liveGamesCollection => _db.collection('live_games');

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

  Stream<List<EventWithStatsStatus>> getPastEventsWithStatsStatus() {
    print("--- Subscribing to Past Events Stream ---");
    return _db
        .collection('scheduleEvents')
        .where('dateTime', isLessThan: DateTime.now())
        .orderBy('dateTime', descending: true)
        .snapshots()
        .asyncMap((eventSnapshot) async {
      // --- DEBUGGING BLOCK ---
      print(
          "--- Stream Updated: Found ${eventSnapshot.docs.length} past events ---");
      for (final doc in eventSnapshot.docs) {
        final data = doc.data();
        print(
            "  - Event ID: ${doc.id}, Title: ${data['title']}, Time: ${data['dateTime']}");
      }
      // --- END DEBUGGING BLOCK ---

      List<EventWithStatsStatus> processedEvents = [];
      if (eventSnapshot.docs.isEmpty) {
        return processedEvents;
      }

      List<Future<bool>> statChecks = [];
      for (final doc in eventSnapshot.docs) {
        statChecks.add(doesEventHaveStats(doc.id));
      }

      List<bool> hasStatsResults = await Future.wait(statChecks);

      for (int i = 0; i < eventSnapshot.docs.length; i++) {
        final event =
            app_event.ScheduleEvent.fromMap(eventSnapshot.docs[i].data());
        final hasStats = hasStatsResults[i];
        processedEvents
            .add(EventWithStatsStatus(event: event, hasStats: hasStats));
      }

      print(
          "--- Processed ${processedEvents.length} events with stat status ---");
      return processedEvents;
    });
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

// Checks if stats exist for a given event
  Future<bool> doesEventHaveStats(String eventId) async {
    final query = await gameStatsCollection
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

// Gets all player stats for a single game
  Future<List<PlayerGameStats>> getStatsForEvent(String eventId) async {
    final query =
        await gameStatsCollection.where('eventId', isEqualTo: eventId).get();

    return query.docs
        .map((doc) => PlayerGameStats.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
  }

// Saves the stats for a list of players in a single batch operation
  Future<void> saveStatsForEvent(
      String eventId, List<PlayerGameStats> stats) async {
    final batch = _db.batch();

    for (final playerStats in stats) {
      // Use the player's user ID as the document ID for easy lookup
      final docRef =
          gameStatsCollection.doc('${eventId}_${playerStats.userId}');
      batch.set(docRef, playerStats.toMap());
    }

    await batch.commit();
  }

  Future<List<app_event.ScheduleEvent>> getEventsForToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final snapshot = await _db
        .collection('scheduleEvents')
        .where('dateTime', isGreaterThanOrEqualTo: startOfDay)
        .where('dateTime', isLessThan: endOfDay)
        .orderBy('dateTime')
        .get();

    return snapshot.docs
        .map((doc) =>
            app_event.ScheduleEvent.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<app_event.ScheduleEvent>> getUpcomingEvents() async {
    final now = DateTime.now();
    final tomorrow =
        DateTime(now.year, now.month, now.day).add(Duration(days: 1));
    final sevenDaysFromNow = tomorrow.add(Duration(days: 7));

    final snapshot = await _db
        .collection('scheduleEvents')
        .where('dateTime', isGreaterThanOrEqualTo: tomorrow)
        .where('dateTime', isLessThan: sevenDaysFromNow)
        .orderBy('dateTime')
        .limit(5) // Limit to 5 upcoming events to avoid clutter
        .get();

    return snapshot.docs
        .map((doc) =>
            app_event.ScheduleEvent.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

// NEW: We also need a way to check for a live game document
  Future<DocumentSnapshot?> getLiveGame(String eventId) {
    return _db.collection('live_games').doc(eventId).get();
  }

  Future<void> saveLiveGame(LiveGame game) {
    // Use the eventId as the document ID for easy lookup
    return liveGamesCollection.doc(game.eventId).set(game.toMap());
  }

  Future<void> deleteLiveGame(String eventId) {
    return liveGamesCollection.doc(eventId).delete();
  }
}
