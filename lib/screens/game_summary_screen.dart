// lib/screens/game_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/game_stats.dart';
import '../screens/schedule_screen.dart' as app_event;
import '../services/firebase_service.dart';

class GameSummaryScreen extends StatefulWidget {
  final app_event.ScheduleEvent event;

  const GameSummaryScreen({Key? key, required this.event}) : super(key: key);

  @override
  _GameSummaryScreenState createState() => _GameSummaryScreenState();
}

class _GameSummaryScreenState extends State<GameSummaryScreen> {
  late Future<List<PlayerGameStats>> _statsFuture;

  @override
  void initState() {
    super.initState();
    // The screen fetches its own data based on the event ID
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    _statsFuture = firebaseService.getStatsForEvent(widget.event.id);
  }

  // Helper to calculate shooting percentages safely
  String _calculatePercentage(int made, int attempted) {
    if (attempted == 0) return '0.0%';
    return ((made / attempted) * 100).toStringAsFixed(1) + '%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Summary for ${widget.event.title}'),
      ),
      body: FutureBuilder<List<PlayerGameStats>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading stats: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No stats found for this event.'));
          }

          final stats = snapshot.data!;
          // Sort players by points for a classic box score feel
          stats.sort((a, b) => b.totals.pts.compareTo(a.totals.pts));

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columnSpacing: 24,
                columns: const [
                  DataColumn(label: Text('Player')),
                  DataColumn(label: Text('MP'), numeric: true),
                  DataColumn(label: Text('PTS'), numeric: true),
                  DataColumn(label: Text('REB'), numeric: true),
                  DataColumn(label: Text('AST'), numeric: true),
                  DataColumn(label: Text('STL'), numeric: true),
                  DataColumn(label: Text('BLK'), numeric: true),
                  DataColumn(label: Text('TOV'), numeric: true),
                  DataColumn(label: Text('FG%')),
                  DataColumn(label: Text('3P%')),
                  DataColumn(label: Text('FT%')),
                ],
                rows: stats.map((playerStats) {
                  final totals = playerStats.totals;
                  return DataRow(cells: [
                    DataCell(Text(playerStats.playerName,
                        style: TextStyle(fontWeight: FontWeight.bold))),
                    DataCell(Text(totals.mp.toStringAsFixed(1))),
                    DataCell(Text(totals.pts.toString())),
                    DataCell(Text(totals.reb.toString())),
                    DataCell(Text(totals.ast.toString())),
                    DataCell(Text(totals.stl.toString())),
                    DataCell(Text(totals.blk.toString())),
                    DataCell(Text(totals.tov.toString())),
                    DataCell(
                        Text(_calculatePercentage(totals.fgm, totals.fga))),
                    DataCell(
                        Text(_calculatePercentage(totals.fgm3, totals.fga3))),
                    DataCell(
                        Text(_calculatePercentage(totals.ftm, totals.fta))),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
