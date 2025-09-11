// lib/models/live_game.dart

import '../models/game_stats.dart';
import '../models/user.dart';

// Represents a single action for the undo stack
class GameAction {
  // We'll implement this later if needed. For now, a simpler state copy is safer.
}

// Manages the entire state of a game being tracked live
class LiveGame {
  final String eventId;
  final String coachId; // Track which coach started the game

  final List<User> participants;
  final Map<String, PlayerGameStats> playerStats; // Maps userId to their stats
  final List<String> onCourt; // List of userIds on court
  final List<String> onBench; // List of userIds on bench
  String currentQuarter;

  LiveGame({
    required this.eventId,
    required this.coachId,
    required this.participants,
    required this.playerStats,
    required this.onCourt,
    required this.onBench,
    this.currentQuarter = 'Q1',
  });

  // Factory to create a new game from a list of players
  factory LiveGame.startNew({
    required String eventId,
    required List<User> participants,
    required String coachId,
    required List<String> onCourtIds, // Now receives the starters
  }) {
    final stats = {
      for (var p in participants)
        p.id: PlayerGameStats(
          id: '',
          eventId: eventId,
          userId: p.id,
          playerName: p.name ?? 'Unknown',
          quarters: {'Q1': StatSet()},
          onCourtStartTime: onCourtIds.contains(p.id) ? DateTime.now() : null,
        )
    };

    // Calculate bench players based on who is NOT on court
    final onBenchIds = participants
        .map((p) => p.id)
        .where((id) => !onCourtIds.contains(id))
        .toList();

    return LiveGame(
      eventId: eventId,
      coachId: coachId,
      participants: participants,
      playerStats: stats,
      onCourt: onCourtIds,
      onBench: onBenchIds,
    );
  }

  // Creates a deep copy of the current state. Essential for the Undo feature.
  LiveGame copy() {
    final copiedStats = {
      for (var entry in playerStats.entries)
        entry.key: PlayerGameStats(
          id: entry.value.id,
          eventId: entry.value.eventId,
          userId: entry.value.userId,
          playerName: entry.value.playerName,
          totals: StatSet.fromMap(entry.value.totals.toMap()),
          quarters: entry.value.quarters.map(
              (key, value) => MapEntry(key, StatSet.fromMap(value.toMap()))),
          // --- ADD THIS LINE ---
          onCourtStartTime: entry.value.onCourtStartTime,
        )
    };

    return LiveGame(
      eventId: eventId,
      coachId: coachId,
      participants: participants,
      playerStats: copiedStats,
      onCourt: List.from(onCourt),
      onBench: List.from(onBench),
      currentQuarter: currentQuarter,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'coachId': coachId,
      'currentQuarter': currentQuarter,
      'onCourt': onCourt,
      'onBench': onBench,
      // Convert the playerStats map into a Firestore-compatible map
      'playerStats': playerStats.map((key, value) {
        // We only need to save the totals for the live game backup
        return MapEntry(key, {
          'totals': value.totals.toMap(),
          'quarters': value.quarters
              .map((qKey, qValue) => MapEntry(qKey, qValue.toMap())),
        });
      }),
    };
  }

  // Creates a LiveGame object from a Firestore document
  factory LiveGame.fromMap(Map<String, dynamic> map, List<User> participants) {
    final playerStatsData = map['playerStats'] as Map<String, dynamic>;

    final stats = {
      for (var p in participants)
        p.id: PlayerGameStats(
          id: '',
          eventId: map['eventId'],
          userId: p.id,
          playerName: p.name ?? 'Unknown',
          totals: StatSet.fromMap(playerStatsData[p.id]['totals']),
          quarters:
              (playerStatsData[p.id]['quarters'] as Map<String, dynamic>).map(
            (key, value) => MapEntry(key, StatSet.fromMap(value)),
          ),
        )
    };

    return LiveGame(
      eventId: map['eventId'],
      coachId: map['coachId'],
      participants: participants,
      playerStats: stats,
      onCourt: List<String>.from(map['onCourt']),
      onBench: List<String>.from(map['onBench']),
      currentQuarter: map['currentQuarter'],
    );
  }
}
