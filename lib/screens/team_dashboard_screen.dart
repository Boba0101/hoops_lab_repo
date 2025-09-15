// lib/screens/team_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/team_stats_summary.dart';
import '../models/game_stats.dart';
import '../models/user.dart';

import '../services/auth_service.dart';
import '../services/firebase_service.dart';

import '../widgets/performance_trend_chart.dart';
import '../widgets/game_log_table.dart';

class _PlayerDashboardData {
  final PlayerSeasonAverage myAverages;
  final List<PlayerGameStats> myGameLog;
  final List<FlSpot> myPerformanceTrend;
  final TeamStatsSummary teamSummaryForContext;

  _PlayerDashboardData({
    required this.myAverages,
    required this.myGameLog,
    required this.myPerformanceTrend,
    required this.teamSummaryForContext,
  });
}

class TeamDashboardScreen extends StatefulWidget {
  const TeamDashboardScreen({Key? key}) : super(key: key);

  @override
  _TeamDashboardScreenState createState() => _TeamDashboardScreenState();
}

class _TeamDashboardScreenState extends State<TeamDashboardScreen> {
  late Future<TeamStatsSummary> _summaryFuture;
  late Future<User?> _userFuture;

  @override
  void initState() {
    super.initState();
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    _summaryFuture = firebaseService.getTeamStatsSummary();
    _userFuture = firebaseService.getUserById(authService.currentUser!.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        // Use a Future.wait to load both the summary and the user role simultaneously
        future: Future.wait([_summaryFuture, _userFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
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

          final summaryData = snapshot.data![0] as TeamStatsSummary;
          final currentUser = snapshot.data![1] as User?;

          return RefreshIndicator(
            onRefresh: () {
              final firebaseService =
                  Provider.of<FirebaseService>(context, listen: false);
              setState(() {
                _summaryFuture = firebaseService.getTeamStatsSummary();
              });
              return _summaryFuture;
            },
            child: (currentUser?.role == 'Coach')
                ? _buildCoachLayout(summaryData)
                : _buildPlayerLayout(summaryData, currentUser?.userId),
          );
        },
      ),
    );
  }

  // --- COACH DASHBOARD UI ---
  Widget _buildCoachLayout(TeamStatsSummary summary) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildRecordAndAveragesCard(summary),
        SizedBox(height: 24),
        _buildPerformanceTrendChart(summary),
        SizedBox(height: 24),
        _buildPlayerLeaderboard(summary),
        SizedBox(height: 24),
        _buildFullRosterStatsTable(summary),
      ],
    );
  }

  // --- PLAYER DASHBOARD UI ---
  Widget _buildPlayerLayout(TeamStatsSummary summary, String? currentUserId) {
    // Find the current player's personal stats from the summary
    final myStats = summary.allPlayerAverages.firstWhere(
      (p) => p.player.userId == currentUserId,
      orElse: () => PlayerSeasonAverage(
          player: User(
              userId: '',
              email: '',
              role: 'Player',
              createdAt: DateTime.now())),
    );

    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildPersonalAveragesCard(myStats),
        SizedBox(height: 24),
        // TODO: Implement Player-specific trend chart
        _buildTeamAveragesContextCard(summary),
      ],
    );
  }

  // --- SHARED & COACH-SPECIFIC WIDGETS ---

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

  Widget _buildPerformanceTrendChart(TeamStatsSummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Recent Scoring Trend",
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: summary.recentScores.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value);
                      }).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 4,
                      belowBarData: BarAreaData(
                          show: true, color: Colors.orange.withOpacity(0.3)),
                    ),
                  ],
                ),
              ),
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
    return ListTile(
      title: Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
      leading: Icon(Icons.star, color: Colors.amber),
      trailing: Text(getStat(player),
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange)),
      subtitle: Text(player.player.name ?? 'Unknown'),
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

  // --- PLAYER-SPECIFIC WIDGETS ---

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

  Widget _buildTeamAveragesContextCard(TeamStatsSummary summary) {
    return Card(
      child: ListTile(
        title: Text("Team Averages (for comparison)"),
        subtitle: Text(
            "${summary.teamPpg.toStringAsFixed(1)} PPG, ${summary.teamRpg.toStringAsFixed(1)} RPG, ${summary.teamApg.toStringAsFixed(1)} APG"),
      ),
    );
  }

  // Helper widget for stat items
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
