// lib/models/live_game.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game_stats.dart';
import '../models/user.dart';

// Represents a single action for the undo stack
class GameAction {
  // We'll implement this later if needed. For now, a simpler state copy is safer.
}

// Manages the entire state of a game being tracked live
class LiveGame {
  final String eventId;
  final String coachId;
  final DateTime eventDateTime; // Store the event's dateTime directly

  final List<User> participants;
  final Map<String, PlayerGameStats> playerStats;
  final List<String> onCourt;
  final List<String> onBench;
  String currentQuarter;

  LiveGame({
    required this.eventId,
    required this.coachId,
    required this.eventDateTime,
    required this.participants,
    required this.playerStats,
    required this.onCourt,
    required this.onBench,
    this.currentQuarter = 'Q1',
  });

  factory LiveGame.startNew({
    required String eventId,
    required DateTime eventDateTime, // Pass the dateTime
    required List<User> participants,
    required String coachId,
    required List<String> onCourtIds,
  }) {
    final stats = {
      for (var p in participants)
        p.userId: PlayerGameStats(
          id: '',
          eventId: eventId,
          userId: p.userId,
          playerName: p.name ?? 'Unknown',
          quarters: {'Q1': StatSet()},
          // --- FIX ---
          eventDateTime: eventDateTime,
          onCourtStartTime:
              onCourtIds.contains(p.userId) ? DateTime.now() : null,
        )
    };
    final onBenchIds = participants
        .map((p) => p.userId)
        .where((id) => !onCourtIds.contains(id))
        .toList();
    return LiveGame(
      eventId: eventId,
      coachId: coachId,
      eventDateTime: eventDateTime,
      participants: participants,
      playerStats: stats,
      onCourt: onCourtIds,
      onBench: onBenchIds,
    );
  }

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
          // --- FIX ---
          eventDateTime: entry.value.eventDateTime,
          onCourtStartTime: entry.value.onCourtStartTime,
        )
    };
    return LiveGame(
      eventId: eventId,
      coachId: coachId,
      eventDateTime: eventDateTime,
      participants: participants,
      playerStats: copiedStats,
      onCourt: List.from(onCourt),
      onBench: List.from(onBench),
      currentQuarter: currentQuarter,
    );
  }

  // toMap and fromMap also need to be updated to handle the dateTime
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'coachId': coachId,
      'eventDateTime': Timestamp.fromDate(eventDateTime),
      'currentQuarter': currentQuarter,
      'onCourt': onCourt,
      'onBench': onBench,
      'playerStats': playerStats.map((key, value) => MapEntry(key, {
            'totals': value.totals.toMap(),
            'quarters': value.quarters
                .map((qKey, qValue) => MapEntry(qKey, qValue.toMap())),
          })),
    };
  }

  factory LiveGame.fromMap(Map<String, dynamic> map, List<User> participants) {
    final playerStatsData = map['playerStats'] as Map<String, dynamic>;
    final eventDT = (map['eventDateTime'] as Timestamp).toDate();
    final stats = {
      for (var p in participants)
        p.userId: PlayerGameStats(
          id: '',
          eventId: map['eventId'],
          userId: p.userId,
          playerName: p.name ?? 'Unknown',
          totals: StatSet.fromMap(playerStatsData[p.userId]['totals']),
          quarters:
              (playerStatsData[p.userId]['quarters'] as Map<String, dynamic>)
                  .map((key, value) => MapEntry(key, StatSet.fromMap(value))),
          // --- FIX ---
          eventDateTime: eventDT,
        )
    };
    return LiveGame(
      eventId: map['eventId'],
      coachId: map['coachId'],
      eventDateTime: eventDT,
      participants: participants,
      playerStats: stats,
      onCourt: List<String>.from(map['onCourt']),
      onBench: List<String>.from(map['onBench']),
      currentQuarter: map['currentQuarter'],
    );
  }
}
