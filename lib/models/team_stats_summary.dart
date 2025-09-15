// lib/models/team_stats_summary.dart

import '../models/user.dart';

/// Holds the calculated season averages for a single player.
class PlayerSeasonAverage {
  final User player; // The full player object for profile info
  final int gameCount;
  final double ppg; // Points Per Game
  final double rpg; // Rebounds Per Game
  final double apg; // Assists Per Game
  final double spg; // Steals Per Game
  final double bpg; // Blocks Per Game
  final double tpg; // Turnovers Per Game
  final double fgPercentage;
  final double a_3pPercentage;
  final double ftPercentage;

  PlayerSeasonAverage({
    required this.player,
    this.gameCount = 0,
    this.ppg = 0.0,
    this.rpg = 0.0,
    this.apg = 0.0,
    this.spg = 0.0,
    this.bpg = 0.0,
    this.tpg = 0.0,
    this.fgPercentage = 0.0,
    this.a_3pPercentage = 0.0,
    this.ftPercentage = 0.0,
  });
}

/// A comprehensive data bundle holding all calculated stats for the dashboard.
class TeamStatsSummary {
  // Team-level stats
  final int wins;
  final int losses;
  final double teamPpg;
  final double teamRpg;
  final double teamApg;

  // Individual player stats and leaderboards
  final List<PlayerSeasonAverage> allPlayerAverages;
  final PlayerSeasonAverage? topScorer;
  final PlayerSeasonAverage? topRebounder;
  final PlayerSeasonAverage? topPlaymaker;

  // Data for trend charts (a list of points scored in the last few games)
  final List<double> recentScores;

  TeamStatsSummary({
    this.wins = 0,
    this.losses = 0,
    this.teamPpg = 0.0,
    this.teamRpg = 0.0,
    this.teamApg = 0.0,
    this.allPlayerAverages = const [],
    this.topScorer,
    this.topRebounder,
    this.topPlaymaker,
    this.recentScores = const [],
  });
}
