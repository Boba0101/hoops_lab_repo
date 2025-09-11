// lib/models/game_stats.dart

import 'package:cloud_firestore/cloud_firestore.dart';

// Represents a map of stats for a single period (e.g., Q1, Q2, or totals)
class StatSet {
  // Calculated Totals
  int pts, reb, fgm, fga;

  // Core Input Stats
  int ast, stl, blk, tov;
  int orb, drb;
  double mp; // Minutes Played

  // Granular Shooting Stats
  int fga2, fgm2; // 2-pointers
  int fga3, fgm3; // 3-pointers
  int fta, ftm; // Free throws

  StatSet({
    // Calculated
    this.pts = 0,
    this.reb = 0,
    this.fgm = 0,
    this.fga = 0,
    // Core
    this.ast = 0,
    this.stl = 0,
    this.blk = 0,
    this.tov = 0,
    this.orb = 0,
    this.drb = 0,
    this.mp = 0.0,
    // Shooting
    this.fga2 = 0,
    this.fgm2 = 0,
    this.fga3 = 0,
    this.fgm3 = 0,
    this.fta = 0,
    this.ftm = 0,
  });

  factory StatSet.fromMap(Map<String, dynamic> map) {
    return StatSet(
      pts: map['pts'] ?? 0,
      reb: map['reb'] ?? 0,
      fgm: map['fgm'] ?? 0,
      fga: map['fga'] ?? 0,
      ast: map['ast'] ?? 0,
      stl: map['stl'] ?? 0,
      blk: map['blk'] ?? 0,
      tov: map['tov'] ?? 0,
      orb: map['orb'] ?? 0,
      drb: map['drb'] ?? 0,
      mp: (map['mp'] as num?)?.toDouble() ?? 0.0,
      fga2: map['fga2'] ?? 0,
      fgm2: map['fgm2'] ?? 0,
      fga3: map['fga3'] ?? 0,
      fgm3: map['fgm3'] ?? 0,
      fta: map['fta'] ?? 0,
      ftm: map['ftm'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pts': pts,
      'reb': reb,
      'fgm': fgm,
      'fga': fga,
      'ast': ast,
      'stl': stl,
      'blk': blk,
      'tov': tov,
      'orb': orb,
      'drb': drb,
      'mp': mp,
      'fga2': fga2,
      'fgm2': fgm2,
      'fga3': fga3,
      'fgm3': fgm3,
      'fta': fta,
      'ftm': ftm,
    };
  }
}

// Represents a single player's full box score for one game
class PlayerGameStats {
  final String id; // Firestore document ID
  final String eventId;
  final String userId;
  final String playerName;

  // FIX: 'totals' is no longer final to allow modification.
  StatSet totals;
  final Map<String, StatSet> quarters;

  DateTime? onCourtStartTime;

  PlayerGameStats({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.playerName,
    required this.quarters,
    StatSet? totals, // It's now an optional parameter.
    this.onCourtStartTime, // Add to constructor
  }) : this.totals =
            totals ?? StatSet(); // If not provided, create an empty StatSet.

  factory PlayerGameStats.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final quartersData = data['quarters'] as Map<String, dynamic>? ?? {};

    return PlayerGameStats(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      playerName: data['playerName'] ?? 'Unknown Player',
      totals: StatSet.fromMap(data['totals'] as Map<String, dynamic>? ?? {}),
      quarters: quartersData.map((key, value) => MapEntry(
            key,
            StatSet.fromMap(value as Map<String, dynamic>),
          )),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'playerName': playerName,
      'totals': totals.toMap(),
      'quarters': quarters.map((key, value) => MapEntry(key, value.toMap())),
    };
  }
}
