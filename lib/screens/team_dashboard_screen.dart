// lib/screens/team_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../models/team_stats_summary.dart';
import '../models/game_stats.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../widgets/performance_trend_chart.dart';
import '../widgets/game_log_table.dart';
import 'player_analytics_screen.dart';

// A data bundle specifically for the Player's Dashboard
class _PlayerDashboardData {
  final PlayerSeasonAverage myAverages;
  final List<PlayerGameStats> myGameLog;
  final List<FlSpot> myPerformanceTrend;
  final TeamStatsSummary teamSummaryForContext;
  final PlayerGameStats? lastGameStats;

  _PlayerDashboardData({
    required this.myAverages,
    required this.myGameLog,
    required this.myPerformanceTrend,
    required this.teamSummaryForContext,
    this.lastGameStats,
  });
}

class TeamDashboardScreen extends StatefulWidget {
  const TeamDashboardScreen({Key? key}) : super(key: key);

  @override
  _TeamDashboardScreenState createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  late Future<dynamic> _dashboardDataFuture;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _fetchDashboardData();
  }

  Future<dynamic> _fetchDashboardData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    _currentUser =
        await firebaseService.getUserById(authService.currentUser!.uid);

    if (_currentUser?.role == 'Coach') {
      return firebaseService.getTeamStatsSummary();
    } else if (_currentUser != null) {
      return _loadPlayerData(firebaseService, _currentUser!.userId);
    } else {
      throw Exception("User not found or role is not defined.");
    }
  }

  Future<_PlayerDashboardData> _loadPlayerData(
      FirebaseService service, String userId) async {
    final teamSummary = await service.getTeamStatsSummary();
    final myGameLog = await service.getStatsForPlayer(userId);

    final myAverages = teamSummary.allPlayerAverages.firstWhere(
      (p) => p.player.userId == userId,
      orElse: () => PlayerSeasonAverage(player: _currentUser!),
    );

    final recentGames = myGameLog.take(10).toList().reversed.toList();
    final trendData = recentGames.asMap().entries.map((e) {
      return FlSpot(
          e.key.toDouble(), _calculatePerformanceScore(e.value.totals));
    }).toList();

    final PlayerGameStats? lastGame =
        myGameLog.isNotEmpty ? myGameLog.first : null;

    return _PlayerDashboardData(
      myAverages: myAverages,
      myGameLog: myGameLog,
      myPerformanceTrend: trendData,
      teamSummaryForContext: teamSummary,
      lastGameStats: lastGame,
    );
  }

  double _calculatePerformanceScore(StatSet stats) {
    return (stats.pts + stats.reb + stats.ast + stats.stl + stats.blk)
            .toDouble() -
        ((stats.fga - stats.fgm) + (stats.fta - stats.ftm) + stats.tov)
            .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<dynamic>(
        future: _dashboardDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text("Error loading dashboard: ${snapshot.error}"));
          }
          if (!snapshot.hasData) {
            return Center(child: Text("No data available."));
          }

          return RefreshIndicator(
            onRefresh: () {
              setState(() {
                _dashboardDataFuture = _fetchDashboardData();
              });
              return _dashboardDataFuture;
            },
            child: (_currentUser?.role == 'Coach')
                ? _buildCoachLayout(snapshot.data as TeamStatsSummary)
                : _buildPlayerLayout(snapshot.data as _PlayerDashboardData),
          );
        },
      ),
    );
  }

  // --- COACH DASHBOARD UI ---
  Widget _buildCoachLayout(TeamStatsSummary summary) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(16),
      children: [
        _buildRecordAndAveragesCard(summary),
        SizedBox(height: 24),
        PerformanceTrendChart(
            trendData: summary.recentScores
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList()),
        SizedBox(height: 24),
        _buildPlayerLeaderboard(summary),
        SizedBox(height: 24),
        _buildFullRosterStatsTable(summary),
      ],
    );
  }

  // --- PLAYER DASHBOARD UI (UPGRADED) ---
  Widget _buildPlayerLayout(_PlayerDashboardData data) {
    return ListView(
      padding: EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildPersonalAveragesCard(data.myAverages),
        SizedBox(height: 24),
        _buildRecentVsOverallCard(data.lastGameStats, data.myAverages),
        SizedBox(height: 24),
        PerformanceTrendChart(trendData: data.myPerformanceTrend),
        SizedBox(height: 24),
        GameLogTable(gameLog: data.myGameLog),
        SizedBox(height: 24),
        _buildTeamAveragesContextCard(data.teamSummaryForContext),
      ],
    );
  }

  // --- WIDGET BUILDER METHODS ---

  Widget _buildRecordAndAveragesCard(TeamStatsSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Season Overview",
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('${summary.wins} - ${summary.losses}', "Record"),
                _buildStatItem(summary.teamPpg.toStringAsFixed(1), "PPG"),
                _buildStatItem(summary.teamRpg.toStringAsFixed(1), "RPG"),
                _buildStatItem(summary.teamApg.toStringAsFixed(1), "APG"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerLeaderboard(TeamStatsSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Season Leaders",
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            _buildLeaderboardRow(
                "Points", summary.topScorer, (s) => s.ppg.toStringAsFixed(1)),
            Divider(),
            _buildLeaderboardRow("Rebounds", summary.topRebounder,
                (s) => s.rpg.toStringAsFixed(1)),
            Divider(),
            _buildLeaderboardRow("Assists", summary.topPlaymaker,
                (s) => s.apg.toStringAsFixed(1)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(String category, PlayerSeasonAverage? player,
      String Function(PlayerSeasonAverage) getStat) {
    if (player == null)
      return ListTile(title: Text(category), subtitle: Text("N/A"));
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  PlayerAnalyticsScreen(player: player.player))),
      child: ListTile(
        title: Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
        leading: Icon(Icons.star, color: Colors.amber),
        trailing: Text(getStat(player),
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange)),
        subtitle: Text(player.player.name ?? 'Unknown'),
      ),
    );
  }

  Widget _buildFullRosterStatsTable(TeamStatsSummary summary) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Full Roster Averages",
                style: Theme.of(context).textTheme.titleLarge),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Player')),
                DataColumn(label: Text('GP'), numeric: true),
                DataColumn(label: Text('PPG'), numeric: true),
                DataColumn(label: Text('RPG'), numeric: true),
                DataColumn(label: Text('APG'), numeric: true),
                DataColumn(label: Text('FG%'), numeric: true),
              ],
              rows: summary.allPlayerAverages
                  .map((p) => DataRow(cells: [
                        DataCell(Text(p.player.name ?? 'N/A')),
                        DataCell(Text(p.gameCount.toString())),
                        DataCell(Text(p.ppg.toStringAsFixed(1))),
                        DataCell(Text(p.rpg.toStringAsFixed(1))),
                        DataCell(Text(p.apg.toStringAsFixed(1))),
                        DataCell(Text('${p.fgPercentage.toStringAsFixed(1)}%')),
                      ]))
                  .toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPersonalAveragesCard(PlayerSeasonAverage myStats) {
    return Card(
      color: Colors.orange.withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Your Season Averages",
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(myStats.ppg.toStringAsFixed(1), "PPG"),
                _buildStatItem(myStats.rpg.toStringAsFixed(1), "RPG"),
                _buildStatItem(myStats.apg.toStringAsFixed(1), "APG"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentVsOverallCard(
      PlayerGameStats? lastGame, PlayerSeasonAverage averages) {
    if (lastGame == null) {
      return SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Last Game vs. Season Average",
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            _buildComparisonRow(
                "Points", lastGame.totals.pts.toDouble(), averages.ppg),
            Divider(height: 24),
            _buildComparisonRow(
                "Rebounds", lastGame.totals.reb.toDouble(), averages.rpg),
            Divider(height: 24),
            _buildComparisonRow(
                "Assists", lastGame.totals.ast.toDouble(), averages.apg),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
      String statName, double lastGameValue, double seasonAverage) {
    IconData trendIcon = Icons.horizontal_rule;
    Color trendColor = Colors.grey;

    if (lastGameValue > seasonAverage) {
      trendIcon = Icons.arrow_upward;
      trendColor = Colors.green;
    } else if (lastGameValue < seasonAverage) {
      trendIcon = Icons.arrow_downward;
      trendColor = Colors.red;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(statName, style: TextStyle(fontSize: 16)),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("Last Game",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(lastGameValue.toStringAsFixed(1),
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Icon(trendIcon, color: trendColor),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Average",
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(seasonAverage.toStringAsFixed(1),
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTeamAveragesContextCard(TeamStatsSummary summary) {
    return Card(
      child: ListTile(
        title: Text("Team Averages (for comparison)"),
        subtitle: Text(
            "${summary.teamPpg.toStringAsFixed(1)} PPG, ${summary.teamRpg.toStringAsFixed(1)} RPG, ${summary.teamApg.toStringAsFixed(1)} APG"),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orange)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[400])),
      ],
    );
  }
}
