// lib/screens/match_history_screen.dart

//packages
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoops_lab_v1/models/game_stats.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

//services
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

//models
import '../models/user.dart';
import '../models/event_with_stats_status.dart';
import '../screens/schedule_screen.dart' as app_event;

//screens
import 'manual_stats_screen.dart';
import 'game_summary_screen.dart';

class MatchHistoryScreen extends StatefulWidget {
  @override
  _MatchHistoryScreenState createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  // The state is now much simpler!
  String? _currentUserRole;
  late Stream<List<EventWithStatsStatus>> _pastEventsStream;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    // Initialize the new stream
    _pastEventsStream = Provider.of<FirebaseService>(context, listen: false)
        .getPastEventsWithStatsStatus();
  }

  Future<void> _fetchUserRole() async {
    // This part remains the same.
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      final user = await Provider.of<FirebaseService>(context, listen: false)
          .getUserById(authService.currentUser!.uid);
      if (mounted) {
        setState(() {
          _currentUserRole = user?.role;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<EventWithStatsStatus>>(
        stream: _pastEventsStream,
        builder: (context, snapshot) {
          // --- REFACTORED LOGIC ---
          // 1. Handle loading state first
          if (snapshot.connectionState == ConnectionState.waiting ||
              _currentUserRole == null) {
            return Center(child: CircularProgressIndicator());
          }

          // 2. Handle errors
          if (snapshot.hasError) {
            print(
                "Match History Error: ${snapshot.error}"); // Good for debugging
            return Center(child: Text('An error occurred.'));
          }

          // 3. Handle empty data state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No past events found.'));
          }

          // 4. If we have data, build the list
          final eventsWithStatus = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _pastEventsStream =
                    Provider.of<FirebaseService>(context, listen: false)
                        .getPastEventsWithStatsStatus();
              });
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: eventsWithStatus.length,
              itemBuilder: (context, index) {
                final item = eventsWithStatus[index];
                return _buildEventCard(context, item.event, item.hasStats);
              },
            ),
          );
        },
      ),
    );
  }

  // The card and navigation logic are still here, but no analysis is performed.
  Widget _buildEventCard(
      BuildContext context, app_event.ScheduleEvent event, bool hasStats) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    // --- LOGIC TO DETERMINE OUTCOME AND COLOR ---
    Color scoreColor = Colors.grey; // Default color for ties or no score
    String resultText = '';

    if (event.ourScore != null && event.opponentScore != null) {
      if (event.ourScore! > event.opponentScore!) {
        scoreColor = Colors.green;
        resultText = 'W'; // Add a "W" for Win
      } else if (event.ourScore! < event.opponentScore!) {
        scoreColor = Colors.red;
        resultText = 'L'; // Add an "L" for Loss
      } else {
        resultText = 'T'; // Add a "T" for Tie
      }
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Event details
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(event.title,
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(
                        DateFormat('MMM d, yyyy @ h:mm a')
                            .format(event.dateTime),
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),

                // Right side: Final score with color coding
                if (event.ourScore != null && event.opponentScore != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: scoreColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(resultText,
                            style: TextStyle(
                                color: scoreColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        SizedBox(height: 4),
                        Text(
                          "${event.ourScore} - ${event.opponentScore}",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: scoreColor),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            // The action buttons section remains the same
            if (hasStats)
              Row(
                children: [
                  Expanded(
                      child: ElevatedButton(
                          child: Text('View Summary'),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      GameSummaryScreen(event: event))))),
                  SizedBox(width: 8),
                  if (_currentUserRole == 'Coach')
                    Expanded(
                        child: ElevatedButton(
                            child: Text('Edit Stats'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange),
                            onPressed: () => _navigateToStatsScreen(
                                context, event,
                                isEditing: true))),
                ],
              )
            else if (_currentUserRole == 'Coach')
              ElevatedButton(
                  child: Text('Add Stats'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () =>
                      _navigateToStatsScreen(context, event, isEditing: false))
            else
              Text('Stats have not been recorded yet.',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// RENAMED and UPDATED: This function now handles both adding and editing.
Future<void> _navigateToStatsScreen(
    BuildContext context, app_event.ScheduleEvent event,
    {required bool isEditing}) async {
  // We no longer need to manually refresh the state, because the StreamBuilder
  // will handle it automatically when the `ourScore` field is updated in Firestore.
  // The logic becomes simpler.

  final firebaseService = Provider.of<FirebaseService>(context, listen: false);
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

    List<PlayerGameStats>? existingStats;
    if (isEditing) {
      existingStats = await firebaseService.getStatsForEvent(event.id);
    }

    Navigator.pop(context); // Dismiss loading indicator

    if (context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ManualStatsScreen(
            event: event,
            participants: participants,
            existingStats: existingStats,
          ),
        ),
      );
      // NO need for setState or refreshing the future here!
    }
  } catch (e) {
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
  }
}
