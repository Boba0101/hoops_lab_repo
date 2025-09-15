// lib/screens/player_analytics_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/team_stats_summary.dart'; // We can reuse PlayerSeasonAverage
import '../models/game_stats.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';
import '../widgets/performance_trend_chart.dart';
import '../widgets/game_log_table.dart';

// A helper class to bundle all the data needed for this screen
class _PlayerAnalyticsData {
  final PlayerSeasonAverage seasonAverages;
  final List<PlayerGameStats> gameLog;
  final List<FlSpot> performanceTrendData;

  _PlayerAnalyticsData({
    required this.seasonAverages,
    required this.gameLog,
    required this.performanceTrendData,
  });
}

class PlayerAnalyticsScreen extends StatefulWidget {
  final User player;

  const PlayerAnalyticsScreen({Key? key, required this.player})
      : super(key: key);

  @override
  _PlayerAnalyticsScreenState createState() => _PlayerAnalyticsScreenState();
}

class _PlayerAnalyticsScreenState extends State<PlayerAnalyticsScreen> {
  late Future<_PlayerAnalyticsData> _analyticsDataFuture;

  @override
  void initState() {
    super.initState();
    _analyticsDataFuture = _loadAnalyticsData();
  }

  // The "workhorse" method to fetch and process all data for this screen
  Future<_PlayerAnalyticsData> _loadAnalyticsData() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    // 1. Fetch all game stats for the player (already sorted by date)
    final gameLog =
        await firebaseService.getStatsForPlayer(widget.player.userId);

    if (gameLog.isEmpty) {
      return _PlayerAnalyticsData(
        seasonAverages: PlayerSeasonAverage(player: widget.player),
        gameLog: [],
        performanceTrendData: [],
      );
    }

    // 2. Calculate season averages
    int gameCount = gameLog.length;
    int totalPts = gameLog.fold(0, (sum, s) => sum + s.totals.pts);
    int totalReb = gameLog.fold(0, (sum, s) => sum + s.totals.reb);
    int totalAst = gameLog.fold(0, (sum, s) => sum + s.totals.ast);
    int totalFga = gameLog.fold(0, (sum, s) => sum + s.totals.fga);
    int totalFgm = gameLog.fold(0, (sum, s) => sum + s.totals.fgm);

    final seasonAverages = PlayerSeasonAverage(
      player: widget.player,
      gameCount: gameCount,
      ppg: totalPts / gameCount,
      rpg: totalReb / gameCount,
      apg: totalAst / gameCount,
      fgPercentage: totalFga > 0 ? (totalFgm / totalFga) * 100 : 0.0,
    );

    // 3. Prepare data for the performance trend chart
    final recentGamesForChart = gameLog.take(10).toList().reversed.toList();
    final performanceTrendData =
        recentGamesForChart.asMap().entries.map((entry) {
      int index = entry.key;
      PlayerGameStats stats = entry.value;

      // --- THIS IS THE FIX ---
      // Instead of calling a deleted method, we now access the getter on the StatSet.
      return FlSpot(index.toDouble(), stats.totals.performanceScore);
    }).toList();

    // 4. Return the complete data bundle
    return _PlayerAnalyticsData(
      seasonAverages: seasonAverages,
      gameLog: gameLog,
      performanceTrendData: performanceTrendData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text('${widget.player.name ?? 'Player'} Analytics')),
      body: FutureBuilder<_PlayerAnalyticsData>(
        future: _analyticsDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(
                child: Text("Error loading analytics: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.gameLog.isEmpty)
            return Center(
                child:
                    Text("${widget.player.name} has no recorded game stats."));

          final data = snapshot.data!;
          // The build content is now cleaner
          return _buildContent(data);
        },
      ),
    );
  }

  Widget _buildContent(_PlayerAnalyticsData data) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        _buildPlayerHeaderCard(widget.player),
        SizedBox(height: 24),
        _buildSeasonAveragesCard(data.seasonAverages),
        SizedBox(height: 24),
        // --- USING THE REUSABLE WIDGETS ---
        PerformanceTrendChart(trendData: data.performanceTrendData),
        SizedBox(height: 24),
        GameLogTable(gameLog: data.gameLog),
      ],
    );
  }

  Widget _buildPlayerHeaderCard(User player) {
    return Card(
      child: ListTile(
        title: Text(player.name ?? 'Unknown',
            style: Theme.of(context).textTheme.headlineSmall),
        subtitle: Text(
          '${player.position ?? 'N/A'} | ${player.height?.toInt() ?? '-'} cm | ${player.weight?.toInt() ?? '-'} kg',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Colors.grey[400]),
        ),
      ),
    );
  }

  Widget _buildSeasonAveragesCard(PlayerSeasonAverage averages) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Season Averages (${averages.gameCount} Games)",
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(averages.ppg.toStringAsFixed(1), "PPG"),
                _buildStatItem(averages.rpg.toStringAsFixed(1), "RPG"),
                _buildStatItem(averages.apg.toStringAsFixed(1), "APG"),
                _buildStatItem(
                    '${averages.fgPercentage.toStringAsFixed(1)}%', "FG%"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTrendChart(List<FlSpot> trendData) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Performance Score Trend (Last ${trendData.length} Games)",
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                      show: true,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: Colors.grey[800]!, strokeWidth: 0.5)),
                  titlesData: FlTitlesData(
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles:
                                false)), // Hide x-axis labels for simplicity
                  ),
                  borderData: FlBorderData(
                      show: true, border: Border.all(color: Colors.grey[800]!)),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trendData,
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 4,
                      dotData: FlDotData(show: true),
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

  Widget _buildGameLogTable(List<PlayerGameStats> gameLog) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("Full Game Log",
                style: Theme.of(context).textTheme.titleLarge),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Date')),
                DataColumn(label: Text('PTS'), numeric: true),
                DataColumn(label: Text('REB'), numeric: true),
                DataColumn(label: Text('AST'), numeric: true),
                DataColumn(label: Text('TOV'), numeric: true),
                DataColumn(label: Text('STL'), numeric: true),
                DataColumn(label: Text('BLK'), numeric: true),
              ],
              rows: gameLog
                  .map((stats) => DataRow(cells: [
                        DataCell(
                            Text(DateFormat.yMd().format(stats.eventDateTime))),
                        DataCell(Text(stats.totals.pts.toString())),
                        DataCell(Text(stats.totals.reb.toString())),
                        DataCell(Text(stats.totals.ast.toString())),
                        DataCell(Text(stats.totals.tov.toString())),
                        DataCell(Text(stats.totals.stl.toString())),
                        DataCell(Text(stats.totals.blk.toString())),
                      ]))
                  .toList(),
            ),
          )
        ],
      ),
    );
  }

  // Reusable helper for stat display items
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
