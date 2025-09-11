// lib/screens/coach_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/user.dart';
import '../models/game_stats.dart';
import '../screens/schedule_screen.dart' as app_event;
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../widgets/confirm_starters_dialog.dart';
import 'player_detail_screen.dart';
import 'live_tally_screen.dart';

// A helper class to hold all the data for our dashboard in a clean package.
class _CoachDashboardData {
  final app_event.ScheduleEvent? gameDayEvent;
  final app_event.ScheduleEvent? upcomingEvent;
  final PlayerGameStats? mvp;
  final PlayerGameStats? needsImprovement;
  final String analysisTitle;

  _CoachDashboardData({
    this.gameDayEvent,
    this.upcomingEvent,
    this.mvp,
    this.needsImprovement,
    this.analysisTitle = "No games with stats found.",
  });
}

class CoachHomeScreen extends StatefulWidget {
  const CoachHomeScreen({Key? key}) : super(key: key);

  @override
  _CoachHomeScreenState createState() => _CoachHomeScreenState();
}

class _CoachHomeScreenState extends State<CoachHomeScreen> {
  late Future<_CoachDashboardData> _dashboardDataFuture;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _fetchDashboardData();
  }

  Future<_CoachDashboardData> _fetchDashboardData() async {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    final now = DateTime.now();
    const preGameWindow = Duration(minutes: 60);

    final eventsFutures = await Future.wait([
      firebaseService.getEventsForToday(),
      firebaseService.getUpcomingEvents(),
    ]);
    final todaysEvents = eventsFutures[0];
    final upcomingEvents = eventsFutures[1];

    app_event.ScheduleEvent? gameDayEvent;
    PlayerGameStats? mvp;
    PlayerGameStats? needsImprovement;
    String analysisTitle = "No games with stats found.";

    for (final event in todaysEvents) {
      final liveGameDoc = await firebaseService.getLiveGame(event.id);
      if (liveGameDoc != null && liveGameDoc.exists) {
        gameDayEvent = event;
        break;
      }
    }
    if (gameDayEvent == null) {
      for (final event in todaysEvents) {
        if (event.dateTime.isAfter(now.subtract(preGameWindow))) {
          final hasStats = await firebaseService.doesEventHaveStats(event.id);
          if (!hasStats) {
            gameDayEvent = event;
            break;
          }
        }
      }
    }

    final pastEventsSnapshot = await FirebaseFirestore.instance
        .collection('scheduleEvents')
        .where('dateTime', isLessThan: now)
        .orderBy('dateTime', descending: true)
        .limit(10)
        .get();
    for (final doc in pastEventsSnapshot.docs) {
      final event = app_event.ScheduleEvent.fromMap(doc.data());
      if (await firebaseService.doesEventHaveStats(event.id)) {
        final stats = await firebaseService.getStatsForEvent(event.id);
        if (stats.length >= 2) {
          stats.sort((a, b) => _calculatePerformanceScore(b.totals)
              .compareTo(_calculatePerformanceScore(a.totals)));
          analysisTitle = "Latest Game Analysis: ${event.title}";
          mvp = stats.first;
          needsImprovement = stats.last;
          break;
        }
      }
    }

    return _CoachDashboardData(
      gameDayEvent: gameDayEvent,
      upcomingEvent: upcomingEvents.isNotEmpty ? upcomingEvents.first : null,
      mvp: mvp,
      needsImprovement: needsImprovement,
      analysisTitle: analysisTitle,
    );
  }

  int _calculatePerformanceScore(StatSet stats) {
    return (stats.pts + stats.reb + stats.ast + stats.stl + stats.blk) -
        ((stats.fga - stats.fgm) + (stats.fta - stats.ftm) + stats.tov);
  }

  // --- THIS IS THE FULLY IMPLEMENTED NAVIGATION METHOD ---
  Future<void> _navigateToLiveTally(
      BuildContext context, app_event.ScheduleEvent event,
      {DocumentSnapshot? existingLiveGame}) async {
    // If we are resuming a game, we don't need to confirm starters.
    if (existingLiveGame != null) {
      final firebaseService =
          Provider.of<FirebaseService>(context, listen: false);
      showDialog(
          context: context,
          builder: (_) => Center(child: CircularProgressIndicator()),
          barrierDismissible: false);
      try {
        final List<User> participants = [];
        for (String userId in event.participantIds) {
          final user = await firebaseService.getUserById(userId);
          if (user != null) participants.add(user);
        }
        Navigator.pop(context);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LiveTallyScreen(
                event: event,
                participants: participants,
                existingLiveGame: existingLiveGame,
                initialStarters: null, // Not needed when resuming
              ),
            ),
          );
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load player data: $e')));
      }
      return;
    }

    // --- NEW FLOW FOR STARTING A NEW GAME ---
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    showDialog(
        context: context,
        builder: (_) => Center(child: CircularProgressIndicator()),
        barrierDismissible: false);

    try {
      final List<User> participants = [];
      for (String userId in event.participantIds) {
        final user = await firebaseService.getUserById(userId);
        if (user != null) participants.add(user);
      }
      Navigator.pop(context); // Dismiss loading indicator

      if (!mounted) return;

      final Set<String>? starterIds = await showDialog<Set<String>>(
        context: context,
        builder: (_) => ConfirmStartersDialog(participants: participants),
      );

      if (starterIds != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveTallyScreen(
              event: event,
              participants: participants,
              existingLiveGame: null, // No existing game
              initialStarters: starterIds.toList(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load player data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_CoachDashboardData>(
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

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () {
              setState(() {
                _dashboardDataFuture = _fetchDashboardData();
              });
              return _dashboardDataFuture;
            },
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildGameDayCard(data.gameDayEvent),
                SizedBox(height: 16),
                _buildUpcomingEventsCard(data.upcomingEvent),
                SizedBox(height: 24),
                _buildAnalysisCard(
                    data.mvp, data.needsImprovement, data.analysisTitle),
                SizedBox(height: 24),
                Text('Player Roster',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                _buildPlayerRoster(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameDayCard(app_event.ScheduleEvent? event) {
    if (event == null) {
      return Card(
          color: Colors.grey[850],
          child: ListTile(
              leading: Icon(Icons.snooze_outlined, color: Colors.grey[400]),
              title: Text("No Active Events Today")));
    }

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return FutureBuilder<DocumentSnapshot?>(
      future: firebaseService.getLiveGame(event.id),
      builder: (context, liveGameSnapshot) {
        if (liveGameSnapshot.connectionState == ConnectionState.waiting)
          return Card(child: ListTile(title: Text("Checking game status...")));

        final isLive = liveGameSnapshot.data?.exists ?? false;
        if (isLive) {
          // State 1: Game is LIVE
          final liveTitleText = event.eventType == 'training'
              ? "'${event.title}' in progress!"
              : "Live game vs. ${event.opponent} in progress!";

          final liveIcon = event.eventType == 'training'
              ? Icons.directions_run
              : Icons.live_tv;

          return Card(
            color: Colors.red[900],
            child: ListTile(
              leading: Icon(liveIcon, color: Colors.white),
              title: Text(liveTitleText,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: Icon(Icons.arrow_forward_ios, color: Colors.white),
              onTap: () => _navigateToLiveTally(context, event,
                  existingLiveGame: liveGameSnapshot.data),
            ),
          );
        } else {
          // If not live, check if stats have been finalized
          return FutureBuilder<bool>(
            future: firebaseService.doesEventHaveStats(event.id),
            builder: (context, hasStatsSnapshot) {
              if (hasStatsSnapshot.connectionState == ConnectionState.waiting)
                return Card(
                    child: ListTile(title: Text("Checking game status...")));

              final hasStats = hasStatsSnapshot.data ?? false;
              if (hasStats) {
                // State 2: Game is COMPLETE
                return Card(
                  color: Colors.green[900],
                  child: ListTile(
                    leading:
                        Icon(Icons.check_circle, color: Colors.greenAccent),
                    title: Text(
                        "${event.eventType == 'training' ? 'Training' : 'Game'} vs. ${event.opponent} is Complete",
                        style: TextStyle(color: Colors.white)),
                  ),
                );
              } else {
                // --- THIS IS THE FIX ---
                // State 3: Event is PRE-GAME
                // Determine the correct title based on the event type.
                final titleText =
                    event.eventType == 'training' ? "Training Day" : "Game Day";
                final iconData = event.eventType == 'training'
                    ? Icons.fitness_center
                    : Icons.flag;

                return Card(
                  color: Colors.orange.withOpacity(0.2),
                  child: ListTile(
                    leading: Icon(iconData, color: Colors.orange),
                    title: Text("$titleText: ${event.title}",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        "Today at ${DateFormat.jm().format(event.dateTime)}"),
                    trailing: ElevatedButton(
                      child: Text("Start Tally",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Color.from(
                              alpha: 1, red: 0.78, green: 0.122, blue: 0.047)),
                      onPressed: () => _navigateToLiveTally(context, event,
                          existingLiveGame: null),
                    ),
                  ),
                );
              }
            },
          );
        }
      },
    );
  }

  Widget _buildUpcomingEventsCard(app_event.ScheduleEvent? event) {
    if (event == null) return SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: Icon(Icons.calendar_today, color: Colors.grey[400]),
        title: Text("Upcoming: ${event.title}"),
        subtitle:
            Text(DateFormat('EEEE, MMM d @ h:mm a').format(event.dateTime)),
        trailing: Icon(Icons.arrow_forward_ios),
        onTap: () {/* TODO: Navigate to Schedule Tab */},
      ),
    );
  }

  Widget _buildAnalysisCard(
      PlayerGameStats? mvp, PlayerGameStats? needsImprovement, String title) {
    if (mvp == null || needsImprovement == null) {
      return Card(
          child: ListTile(
              title: Text(title),
              subtitle: Text("Not enough data to determine MVP.")));
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Row(
              children: [
                _buildPlayerHighlight("Last Game MVP 🏆", mvp, Colors.green),
                SizedBox(width: 16),
                _buildPlayerHighlight(
                    "Needs Improvement 📈", needsImprovement, Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerHighlight(
      String title, PlayerGameStats playerStats, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          Text(playerStats.playerName, style: TextStyle(fontSize: 18)),
          SizedBox(height: 4),
          Text(
              "${playerStats.totals.pts} PTS | ${playerStats.totals.reb} REB | ${playerStats.totals.ast} AST",
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPlayerRoster() {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);
    return StreamBuilder<List<User>>(
      stream: firebaseService.getPlayersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return Text("No players registered.");

        final players = snapshot.data!;
        return Column(
          children:
              players.map((player) => _buildPlayerListTile(player)).toList(),
        );
      },
    );
  }

  Widget _buildPlayerListTile(User player) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.2),
          child: Text(player.name?.substring(0, 1).toUpperCase() ?? 'P',
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
        ),
        title: Text(player.name ?? 'Unnamed Player',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${player.position ?? 'N/A'} | ${player.height?.toInt() ?? '-'} cm | ${player.weight?.toInt() ?? '-'} kg',
            style: TextStyle(color: Colors.grey[300])),
        trailing: Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => PlayerDetailScreen(player: player))),
      ),
    );
  }
}
