// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

import '../models/game_stats.dart';
import '../models/live_game.dart';
import '../models/user.dart';
import '../models/event_with_stats_status.dart';
import '../models/team_stats_summary.dart';
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
      await usersCollection.doc(user.userId).set(user.toMap());
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

  // Gets all player stats for a single game, now requires the event to get the correct date
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

  Future<String?> getEventTitleById(String eventId) async {
    try {
      final doc = await _db.collection('scheduleEvents').doc(eventId).get();
      if (doc.exists) {
        // Return the 'title' field from the document's data
        return doc.data()?['title'];
      }
      return null; // Return null if the document doesn't exist
    } catch (e) {
      print("Error fetching event title for ID $eventId: $e");
      return null; // Return null on error
    }
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

  Future<List<PlayerGameStats>> getStatsForPlayer(String userId) async {
    print("--- Searching for stats with userId: '$userId' ---");

    // --- THE FIX ---
    // We are removing the .orderBy clause which was causing the query to fail.
    final query = await gameStatsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('eventDateTime', descending: true)
        .get();
    print("--- Query returned ${query.docs.length} documents. ---");

    if (query.docs.isEmpty) {
      return []; // Return early if no documents are found.
    }

    // Convert all documents to PlayerGameStats objects
    final statsList = query.docs
        .map((doc) => PlayerGameStats.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    // --- NEW: Perform the sorting here in the app ---
    statsList.sort((a, b) => b.eventDateTime.compareTo(a.eventDateTime));

    return statsList;
  }

  Future<void> directQueryTest(String userId) async {
    print("=============================================");
    print("--- DIRECT QUERY TEST INITIATED ---");
    print("Searching 'game_stats' for userId: '$userId'");

    try {
      final query = await _db
          .collection('game_stats')
          .where('userId', isEqualTo: userId)
          .get();

      print("Query completed successfully.");
      print("Number of documents found: ${query.docs.length}");

      if (query.docs.isNotEmpty) {
        print("--- DOCUMENT DATA FOUND ---");
        print(query.docs.first.data());
      } else {
        print("--- NO DOCUMENTS MATCHED THE QUERY ---");
      }
    } catch (e) {
      print("!!! DIRECT QUERY FAILED WITH AN ERROR !!!");
      print(e.toString());
    }
    print("=============================================");
  }

  Future<TeamStatsSummary> getTeamStatsSummary() async {
    final stopwatch = Stopwatch()..start();

    // 1. Fetch all necessary data in parallel for performance
    final dataFutures = await Future.wait([
      // Get all players on the roster
      getPlayersStream().first,
      // Get all game stat documents
      gameStatsCollection.get(),
      // Get all past schedule events to determine wins/losses
      _db
          .collection('scheduleEvents')
          .where('dateTime', isLessThan: DateTime.now())
          .orderBy('dateTime', descending: true)
          .get(),
    ]);

    print(
        "--- PERFORMANCE METRIC: Firestore fetch took ${stopwatch.elapsedMilliseconds} ms ---");

    final List<User> allPlayers = dataFutures[0] as List<User>;
    final QuerySnapshot gameStatsSnapshot = dataFutures[1] as QuerySnapshot;
    final QuerySnapshot eventSnapshot = dataFutures[2] as QuerySnapshot;

    final allGameStats = gameStatsSnapshot.docs
        .map((doc) => PlayerGameStats.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>))
        .toList();
    final allPastEvents = eventSnapshot.docs
        .map((doc) =>
            app_event.ScheduleEvent.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    final statsByEvent =
        groupBy(allGameStats, (PlayerGameStats stat) => stat.eventId);

    PlayerSeasonAverage? mvp;
    PlayerSeasonAverage? needsImprovement;

    // --- 2. Process Data: Calculate Individual Player Averages ---
    final List<PlayerSeasonAverage> playerAverages = [];

    final pastEvents = (dataFutures[2] as QuerySnapshot)
        .docs
        .map((doc) =>
            app_event.ScheduleEvent.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    for (final event in pastEvents) {
      if (statsByEvent.containsKey(event.id)) {
        final gameStats = statsByEvent[event.id]!;
        if (gameStats.length >= 2) {
          // Sort THIS GAME's stats by performance score
          gameStats.sort((a, b) =>
              b.totals.performanceScore.compareTo(a.totals.performanceScore));

          // Find the full PlayerSeasonAverage object for the MVP and Needs Improvement player
          mvp = playerAverages.firstWhereOrNull(
              (p) => p.player.userId == gameStats.first.userId);
          needsImprovement = playerAverages.firstWhereOrNull(
              (p) => p.player.userId == gameStats.last.userId);
          break; // Stop after the first game
        }
      }
    }
    for (final player in allPlayers) {
      // Find all the games this specific player participated in
      final playerStats =
          allGameStats.where((stat) => stat.userId == player.userId).toList();
      final gameCount = playerStats.length;

      if (gameCount > 0) {
        // Calculate totals for this player
        int totalPts = playerStats.fold(0, (sum, s) => sum + s.totals.pts);
        int totalReb = playerStats.fold(0, (sum, s) => sum + s.totals.reb);
        int totalAst = playerStats.fold(0, (sum, s) => sum + s.totals.ast);
        int totalStl = playerStats.fold(0, (sum, s) => sum + s.totals.stl);
        int totalBlk = playerStats.fold(0, (sum, s) => sum + s.totals.blk);
        int totalTov = playerStats.fold(0, (sum, s) => sum + s.totals.tov);

        int totalFga = playerStats.fold(0, (sum, s) => sum + s.totals.fga);
        int totalFgm = playerStats.fold(0, (sum, s) => sum + s.totals.fgm);
        int totalTpa = playerStats.fold(0, (sum, s) => sum + s.totals.fga3);
        int totalTpm = playerStats.fold(0, (sum, s) => sum + s.totals.fgm3);
        int totalFta = playerStats.fold(0, (sum, s) => sum + s.totals.fta);
        int totalFtm = playerStats.fold(0, (sum, s) => sum + s.totals.ftm);

        playerAverages.add(PlayerSeasonAverage(
          player: player,
          gameCount: gameCount,
          ppg: totalPts / gameCount,
          rpg: totalReb / gameCount,
          apg: totalAst / gameCount,
          spg: totalStl / gameCount,
          bpg: totalBlk / gameCount,
          tpg: totalTov / gameCount,
          fgPercentage: totalFga > 0 ? (totalFgm / totalFga) * 100 : 0.0,
          a_3pPercentage: totalTpa > 0 ? (totalTpm / totalTpa) * 100 : 0.0,
          ftPercentage: totalFta > 0 ? (totalFtm / totalFta) * 100 : 0.0,
        ));
      }
    }

    // --- 3. Process Data: Calculate Team-Level Stats ---
    int wins = 0;
    int losses = 0;
    for (final event in allPastEvents) {
      if (event.ourScore != null && event.opponentScore != null) {
        if (event.ourScore! > event.opponentScore!) {
          wins++;
        } else if (event.ourScore! < event.opponentScore!) {
          losses++;
        }
      }
    }

    final totalTeamGamesWithStats =
        allPastEvents.where((e) => e.ourScore != null).length;
    double teamPpg = 0.0;
    double teamRpg = 0.0;
    double teamApg = 0.0;

    if (totalTeamGamesWithStats > 0) {
      int totalTeamPts = allGameStats.fold(0, (sum, s) => sum + s.totals.pts);
      int totalTeamReb = allGameStats.fold(0, (sum, s) => sum + s.totals.reb);
      int totalTeamAst = allGameStats.fold(0, (sum, s) => sum + s.totals.ast);
      teamPpg = totalTeamPts / totalTeamGamesWithStats;
      teamRpg = totalTeamReb / totalTeamGamesWithStats;
      teamApg = totalTeamAst / totalTeamGamesWithStats;
    }

    // --- 4. Process Data: Find Leaderboard Players ---
    // Sort by highest PPG for top scorer, etc.
    playerAverages.sort((a, b) => b.ppg.compareTo(a.ppg));
    final topScorer = playerAverages.isNotEmpty ? playerAverages.first : null;

    playerAverages.sort((a, b) => b.rpg.compareTo(a.rpg));
    final topRebounder =
        playerAverages.isNotEmpty ? playerAverages.first : null;

    playerAverages.sort((a, b) => b.apg.compareTo(a.apg));
    final topPlaymaker =
        playerAverages.isNotEmpty ? playerAverages.first : null;

    // Restore original sort order (e.g., by name)
    playerAverages.sort((a, b) => a.player.name!.compareTo(b.player.name!));

    // --- 5. Process Data: Get recent scores for the trend chart ---
    List<double> recentScores = [];
    // Take the last 5 games that had a score recorded
    final recentGames =
        allPastEvents.where((e) => e.ourScore != null).take(5).toList();
    // Reverse it so the chart goes from oldest to newest
    for (final event in recentGames.reversed) {
      recentScores.add(event.ourScore!.toDouble());
    }
    stopwatch.stop();
    print(
        "--- PERFORMANCE METRIC: Total dashboard data processing took ${stopwatch.elapsedMilliseconds} ms ---");

    // --- 6. Return the final, complete data bundle ---
    return TeamStatsSummary(
      wins: wins,
      losses: losses,
      teamPpg: teamPpg,
      teamRpg: teamRpg,
      teamApg: teamApg,
      allPlayerAverages: playerAverages,
      topScorer: topScorer,
      topRebounder: topRebounder,
      topPlaymaker: topPlaymaker,
      recentScores: recentScores,
    );
  }
}
