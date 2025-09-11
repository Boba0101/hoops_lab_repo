// lib/screens/live_tally_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hoops_lab_v1/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/live_game.dart';
import '../models/user.dart';
import '../models/game_stats.dart';
import '../screens/schedule_screen.dart' as app_event;
import '../services/firebase_service.dart';
import 'game_summary_screen.dart';

class LiveTallyScreen extends StatefulWidget {
  final app_event.ScheduleEvent event;
  final List<User> participants;

  final DocumentSnapshot? existingLiveGame;
  final List<String>? initialStarters;

  const LiveTallyScreen({
    Key? key,
    required this.event,
    required this.participants,
    this.existingLiveGame,
    this.initialStarters,
  }) : super(key: key);

  @override
  _LiveTallyScreenState createState() => _LiveTallyScreenState();
}

class _LiveTallyScreenState extends State<LiveTallyScreen> {
  late LiveGame _game;
  List<LiveGame> _history = [];
  bool _isLoading = true;
  final Stopwatch _gameClock = Stopwatch();
  Timer? _uiUpdateTimer;
  String _gameClockDisplay = "00:00";
  List<String> _quarters = ["Q1", "Q2", "Q3", "Q4", "OT", "OT2", "OT3"];
  Timer? _persistenceTimer;
  late FirebaseService _firebaseService;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _firebaseService = Provider.of<FirebaseService>(context, listen: false);
    _authService = Provider.of<AuthService>(context, listen: false);
    _initializeGame();
  }

  void _initializeGame() {
    if (widget.existingLiveGame != null && widget.existingLiveGame!.exists) {
      print("RESUMING existing game...");
      // We have a game to resume. Use the fromMap factory.
      final data = widget.existingLiveGame!.data() as Map<String, dynamic>;
      _game = LiveGame.fromMap(data, widget.participants);
    } else {
      print("STARTING new game with confirmed starters...");
      // Use the starter list passed from the dialog
      _game = LiveGame.startNew(
        eventId: widget.event.id,
        participants: widget.participants,
        coachId: _authService.currentUser!.uid,
        onCourtIds: widget.initialStarters!,
      );
      _saveLiveGameState(); // Save the initial state immediately
    }
    _history.add(_game.copy());
    _isLoading = false;
    _startPersistenceTimer();
    setState(() {});
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    _persistenceTimer?.cancel();
    _gameClock.stop();
    super.dispose();
  }

  void _startPersistenceTimer() {
    _persistenceTimer = Timer.periodic(Duration(seconds: 15), (timer) {
      if (_gameClock.isRunning) {
        _saveLiveGameState();
      }
    });
  }

  // --- IMPLEMENTED PERSISTENCE ---
  Future<void> _saveLiveGameState() async {
    print("AUTOSAVING game state to Firestore...");
    // We update player minutes before every save
    _updateAllOnCourtMinutes();
    try {
      await _firebaseService.saveLiveGame(_game);
      print("Autosave successful.");
    } catch (e) {
      print("Autosave failed: $e");
    }
  }

  // --- IMPLEMENTED END GAME LOGIC ---
  Future<void> _endGame() async {
    _uiUpdateTimer?.cancel();
    _persistenceTimer?.cancel();
    _gameClock.stop();
    _updateAllOnCourtMinutes(isFinal: true);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("End Game"),
        content:
            Text("Are you sure you want to end the game and save final stats?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text("End Game")),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        // Save final stats to 'game_stats'
        final finalStats = _game.playerStats.values.toList();
        await _firebaseService.saveStatsForEvent(widget.event.id, finalStats);

        // Delete the temporary game from 'live_games'
        await _firebaseService.deleteLiveGame(widget.event.id);

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (_) => GameSummaryScreen(event: widget.event)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error saving final stats: $e")));
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) _toggleGameClock(); // Resume clock if cancelled
    }
  }

  void _toggleGameClock() {
    if (_gameClock.isRunning) {
      _gameClock.stop();
      _uiUpdateTimer?.cancel();
      _updateAllOnCourtMinutes();
    } else {
      _gameClock.start();
      _setAllOnCourtStartTimes();
      _uiUpdateTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _gameClockDisplay = _formatStopwatchTime(_gameClock.elapsed);
          });
        }
      });
    }
    setState(() {});
  }

  void _nextQuarter() {
    _updateAllOnCourtMinutes();
    int currentIndex = _quarters.indexOf(_game.currentQuarter);
    if (currentIndex < _quarters.length - 1) {
      _recordAction(() {
        _game.currentQuarter = _quarters[currentIndex + 1];
        _game.playerStats.values.forEach((stats) {
          stats.quarters.putIfAbsent(_game.currentQuarter, () => StatSet());
        });
      });
    }
    _setAllOnCourtStartTimes();
  }

  String _formatStopwatchTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _undo() {
    if (_history.length > 1) {
      setState(() {
        _history.removeLast();
        _game = _history.last.copy();
      });
    }
  }

  void _recordAction(VoidCallback action) {
    setState(() {
      action();
      _history.add(_game.copy());
    });
  }

  void _updateAllOnCourtMinutes({bool isFinal = false}) {
    final now = DateTime.now();
    for (var playerId in _game.onCourt) {
      final stats = _game.playerStats[playerId]!;
      if (stats.onCourtStartTime != null) {
        final duration = now.difference(stats.onCourtStartTime!);
        stats.totals.mp += duration.inSeconds / 60.0;
        if (!isFinal) {
          stats.onCourtStartTime = now;
        }
      }
    }
  }

  void _setAllOnCourtStartTimes() {
    final now = DateTime.now();
    for (var playerId in _game.onCourt) {
      _game.playerStats[playerId]!.onCourtStartTime = now;
    }
  }

  void _substitutePlayer(String playerToSubInId, String playerToSubOutId) {
    _recordAction(() {
      final now = DateTime.now();
      final subOutStats = _game.playerStats[playerToSubOutId]!;
      if (subOutStats.onCourtStartTime != null) {
        final duration = now.difference(subOutStats.onCourtStartTime!);
        subOutStats.totals.mp += duration.inSeconds / 60.0;
        subOutStats.onCourtStartTime = null;
      }
      final subInStats = _game.playerStats[playerToSubInId]!;
      if (_gameClock.isRunning) {
        subInStats.onCourtStartTime = now;
      }
      _game.onCourt.remove(playerToSubOutId);
      _game.onBench.add(playerToSubOutId);
      _game.onBench.remove(playerToSubInId);
      _game.onCourt.add(playerToSubInId);
    });
  }

  void _showSubstitutionDialog(String playerToSubInId) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: Text("Substitute Player"),
              content: Text("Who is coming off the court?"),
              actions: _game.onCourt.map((subOutId) {
                final player =
                    _game.participants.firstWhere((p) => p.id == subOutId);
                return TextButton(
                    child: Text(player.name ?? 'Unknown'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _substitutePlayer(playerToSubInId, subOutId);
                    });
              }).toList(),
            ));
  }

  void _addStat(
      String userId, Function(StatSet totals, StatSet quarter) update) {
    _recordAction(() {
      final playerStats = _game.playerStats[userId]!;
      final quarterStats = playerStats.quarters
          .putIfAbsent(_game.currentQuarter, () => StatSet());
      update(playerStats.totals, quarterStats);
    });
  }

  void _onTwoPointsMade(String userId) => _addStat(userId, (t, q) {
        t.pts += 2;
        t.fgm2 += 1;
        t.fga2 += 1;
        q.pts += 2;
        q.fgm2 += 1;
        q.fga2 += 1;
      });
  void _onThreePointsMade(String userId) => _addStat(userId, (t, q) {
        t.pts += 3;
        t.fgm3 += 1;
        t.fga3 += 1;
        q.pts += 3;
        q.fgm3 += 1;
        q.fga3 += 1;
      });
  void _onFreeThrowMade(String userId) => _addStat(userId, (t, q) {
        t.pts += 1;
        t.ftm += 1;
        t.fta += 1;
        q.pts += 1;
        q.ftm += 1;
        q.fta += 1;
      });
  void _onTwoPointsMiss(String userId) => _addStat(userId, (t, q) {
        t.fga2 += 1;
        q.fga2 += 1;
      });
  void _onThreePointsMiss(String userId) => _addStat(userId, (t, q) {
        t.fga3 += 1;
        q.fga3 += 1;
      });
  void _onFreeThrowMiss(String userId) => _addStat(userId, (t, q) {
        t.fta += 1;
        q.fta += 1;
      });
  void _onRebound(String userId) => _addStat(userId, (t, q) {
        t.reb += 1;
        q.reb += 1;
      });
  void _onAssist(String userId) => _addStat(userId, (t, q) {
        t.ast += 1;
        q.ast += 1;
      });
  void _onSteal(String userId) => _addStat(userId, (t, q) {
        t.stl += 1;
        q.stl += 1;
      });
  void _onBlock(String userId) => _addStat(userId, (t, q) {
        t.blk += 1;
        q.blk += 1;
      });
  void _onTurnover(String userId) => _addStat(userId, (t, q) {
        t.tov += 1;
        q.tov += 1;
      });

// Shows a bottom sheet for more stat options
  void _showMoreStatsPanel(String userId, String playerName) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final buttonStyle = ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 50), // Make buttons full width
        );

        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("More Stats for $playerName",
                  style: Theme.of(context).textTheme.titleLarge),
              SizedBox(height: 16),
              ElevatedButton(
                  child: Text('2PT Miss'),
                  style: buttonStyle,
                  onPressed: () {
                    _onTwoPointsMiss(userId);
                    Navigator.pop(context);
                  }),
              SizedBox(height: 8),
              ElevatedButton(
                  child: Text('3PT Miss'),
                  style: buttonStyle,
                  onPressed: () {
                    _onThreePointsMiss(userId);
                    Navigator.pop(context);
                  }),
              SizedBox(height: 8),
              ElevatedButton(
                  child: Text('FT Miss'),
                  style: buttonStyle,
                  onPressed: () {
                    _onFreeThrowMiss(userId);
                    Navigator.pop(context);
                  }),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: ElevatedButton(
                          child: Text('Rebound'),
                          style: buttonStyle,
                          onPressed: () {
                            _onRebound(userId);
                            Navigator.pop(context);
                          })),
                  SizedBox(width: 8),
                  Expanded(
                      child: ElevatedButton(
                          child: Text('Assist'),
                          style: buttonStyle,
                          onPressed: () {
                            _onAssist(userId);
                            Navigator.pop(context);
                          })),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                      child: ElevatedButton(
                          child: Text('Steal'),
                          style: buttonStyle,
                          onPressed: () {
                            _onSteal(userId);
                            Navigator.pop(context);
                          })),
                  SizedBox(width: 8),
                  Expanded(
                      child: ElevatedButton(
                          child: Text('Block'),
                          style: buttonStyle,
                          onPressed: () {
                            _onBlock(userId);
                            Navigator.pop(context);
                          })),
                ],
              ),
              SizedBox(height: 8),
              ElevatedButton(
                  child: Text('Turnover'),
                  style: buttonStyle.copyWith(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.red[800])),
                  onPressed: () {
                    _onTurnover(userId);
                    Navigator.pop(context);
                  }),
            ],
          ),
        );
      },
    );
  }
  // TODO: Add more stat methods

  double _getDisplayMinutesPlayed(PlayerGameStats stats) {
    // Start with the minutes already logged from previous stints on court
    double totalMinutes = stats.totals.mp;

    // If the game clock is running and the player is currently on court...
    if (_gameClock.isRunning && stats.onCourtStartTime != null) {
      // ...calculate the time passed since they were last subbed in...
      final currentStintDuration =
          DateTime.now().difference(stats.onCourtStartTime!);
      // ...and add it to their logged minutes for the live display.
      totalMinutes += currentStintDuration.inSeconds / 60.0;
    }

    return totalMinutes;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
          appBar: AppBar(), body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
          title: Text('Live Tally: ${widget.event.title}'),
          backgroundColor: Color(0xFF1E1E1E),
          actions: [IconButton(icon: Icon(Icons.undo), onPressed: _undo)]),
      body: ListView(
        children: [
          _buildGameControlsHeader(),
          _buildSectionHeader("On Court"),
          // The on-court players are still a simple column
          Column(
            children: _game.onCourt
                .map((userId) => _buildOnCourtPlayerCard(userId))
                .toList(),
          ),
          _buildSectionHeader("Bench"),
          // The bench is now a Wrap of buttons
          _buildBenchButtons(),

          // The end game button is the last item in the scrollable list
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text("End Game & Save Stats",
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _endGame,
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- NEW: Bench UI Widget ---
  Widget _buildBenchButtons() {
    if (_game.onBench.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text("No players on the bench.",
            style: TextStyle(color: Colors.grey[600])),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      // Wrap is perfect for a grid of buttons that adapts to screen size
      child: Wrap(
        spacing: 8.0, // Horizontal space between buttons
        runSpacing: 8.0, // Vertical space between button rows
        children: _game.onBench.map((userId) {
          final player = _game.participants.firstWhere((p) => p.id == userId);
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[800],
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: TextStyle(fontSize: 16),
            ),
            onPressed: () => _showSubstitutionDialog(userId),
            child: Text(player.name ?? 'Unknown'),
          );
        }).toList(),
      ),
    );
  }

  // --- RENAMED & CLEANED UP: On Court Player Card ---
  Widget _buildOnCourtPlayerCard(String userId) {
    final player = _game.participants.firstWhere((p) => p.id == userId);
    final playerStats = _game.playerStats[userId]!;
    final displayMP = _getDisplayMinutesPlayed(playerStats);
    final buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: TextStyle(fontSize: 12));

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${player.name}',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('MP: ${displayMP.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 16, color: Colors.grey[400])),
              ],
            ),
            SizedBox(height: 4),
            Text(
                'PTS: ${playerStats.totals.pts} | REB: ${playerStats.totals.reb} | AST: ${playerStats.totals.ast} | TOV: ${playerStats.totals.tov}'),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ElevatedButton(
                    child: Text('+2 PTS'),
                    style: buttonStyle,
                    onPressed: () => _onTwoPointsMade(userId)),
                ElevatedButton(
                    child: Text('+3 PTS'),
                    style: buttonStyle,
                    onPressed: () => _onThreePointsMade(userId)),
                ElevatedButton(
                    child: Text('+1 FT'),
                    style: buttonStyle,
                    onPressed: () => _onFreeThrowMade(userId)),
                OutlinedButton(
                    child: Text('More...'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[400]),
                    onPressed: () =>
                        _showMoreStatsPanel(userId, player.name ?? 'Player')),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- NEW: Game Controls Widget ---
  Widget _buildGameControlsHeader() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.black.withOpacity(0.2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(_game.currentQuarter,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange)),
              SizedBox(height: 4),
              Text("Quarter", style: TextStyle(color: Colors.grey)),
            ],
          ),
          Column(
            children: [
              Text(_gameClockDisplay,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace')),
              SizedBox(height: 4),
              Text("Game Clock", style: TextStyle(color: Colors.grey)),
            ],
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(
                    _gameClock.isRunning
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    color: Colors.white,
                    size: 30),
                onPressed: _toggleGameClock,
              ),
              Text(_gameClock.isRunning ? "Pause" : "Start",
                  style: TextStyle(color: Colors.grey))
            ],
          ),
          TextButton(
            child:
                Text("Next Quarter >", style: TextStyle(color: Colors.orange)),
            onPressed: _nextQuarter,
          )
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPlayerCard(String userId, bool onCourt) {
    final player = _game.participants.firstWhere((p) => p.id == userId);
    final playerStats = _game.playerStats[userId]!; // Get the full stats object

    // We now call our new helper to get the LIVE minutes played value
    final displayMP = _getDisplayMinutesPlayed(playerStats);

    final buttonStyle = ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: TextStyle(fontSize: 12));

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onCourt ? null : () => _showSubstitutionDialog(userId),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${player.name}',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  // Use the new displayMP variable here
                  Text('MinutesPlayed: ${displayMP.toStringAsFixed(1)}',
                      style: TextStyle(fontSize: 16, color: Colors.grey[400])),
                ],
              ),
              SizedBox(height: 4),
              // Use the saved totals for other stats
              Text(
                  'PTS: ${playerStats.totals.pts} | REB: ${playerStats.totals.reb} | AST: ${playerStats.totals.ast} | TOV: ${playerStats.totals.tov}'),

              if (onCourt) ...[
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ElevatedButton(
                        child: Text('+2 PTS'),
                        style: buttonStyle,
                        onPressed: () => _onTwoPointsMade(userId)),
                    ElevatedButton(
                        child: Text('+3 PTS'),
                        style: buttonStyle,
                        onPressed: () => _onThreePointsMade(userId)),
                    ElevatedButton(
                        child: Text('+1 FT'),
                        style: buttonStyle,
                        onPressed: () => _onFreeThrowMade(userId)),
                    OutlinedButton(
                        child: Text('More...'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[400]),
                        onPressed: () => _showMoreStatsPanel(
                            userId, player.name ?? 'Player')),
                  ],
                )
              ] else ...[
                SizedBox(height: 8),
                Text("Tap to substitute",
                    style: TextStyle(
                        color: Colors.orange, fontStyle: FontStyle.italic)),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
