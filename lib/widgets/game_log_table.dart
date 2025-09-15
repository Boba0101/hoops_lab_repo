// lib/widgets/game_log_table.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/game_stats.dart';

class GameLogTable extends StatelessWidget {
  final List<PlayerGameStats> gameLog;

  const GameLogTable({Key? key, required this.gameLog}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (gameLog.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(child: Text("No game log available.")),
        ),
      );
    }

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
}
