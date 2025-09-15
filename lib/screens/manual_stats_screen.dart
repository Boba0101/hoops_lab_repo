// lib/screens/manual_stats_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../models/game_stats.dart';
import '../services/firebase_service.dart';
import 'schedule_screen.dart' as app_event;

class ManualStatsScreen extends StatefulWidget {
  final app_event.ScheduleEvent event;
  final List<User> participants;
  final List<PlayerGameStats>? existingStats;

  const ManualStatsScreen({
    Key? key,
    required this.event,
    required this.participants,
    this.existingStats,
  }) : super(key: key);

  @override
  _ManualStatsScreenState createState() => _ManualStatsScreenState();
}

class _ManualStatsScreenState extends State<ManualStatsScreen> {
  late Map<String, PlayerGameStats> _statsMap;
  bool _isLoading = false;
  late TextEditingController _opponentScoreController;

  @override
  void initState() {
    super.initState();
    _opponentScoreController = TextEditingController(
        text: widget.event.opponentScore?.toString() ?? '');

    if (widget.existingStats != null && widget.existingStats!.isNotEmpty) {
      _statsMap = {for (var stat in widget.existingStats!) stat.userId: stat};
    } else {
      _statsMap = {
        for (var p in widget.participants)
          p.userId: PlayerGameStats(
            id: '',
            eventId: widget.event.id,
            userId: p.userId,
            playerName: p.name ?? 'Unknown',
            quarters: {},
            // --- THIS IS THE DEFINITIVE FIX ---
            // We now use the exact dateTime from the original scheduled event.
            eventDateTime: widget.event.dateTime,
          )
      };
    }
  }

  @override
  void dispose() {
    _opponentScoreController.dispose();
    super.dispose();
  }

  Future<void> _saveAllStats() async {
    final opponentScore = int.tryParse(_opponentScoreController.text);
    if (widget.event.eventType == 'match' && opponentScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Please enter the opponent\'s score.'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    try {
      int ourTotalScore =
          _statsMap.values.fold(0, (sum, stat) => sum + stat.totals.pts);
      final statsToSave = _statsMap.values.toList();
      await firebaseService.saveStatsForEvent(widget.event.id, statsToSave);
      await FirebaseFirestore.instance
          .collection('scheduleEvents')
          .doc(widget.event.id)
          .update({
        'ourScore': ourTotalScore,
        'opponentScore': opponentScore,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Stats and score saved successfully!'),
            backgroundColor: Colors.green));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _editStatsForPlayer(User player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _EditPlayerStatsForm(
          player: player,
          // Use the correct userId for the map key
          initialStats: _statsMap[player.userId]!.totals,
          onSave: (updatedTotals) {
            setState(() {
              // Use the correct userId for the map key
              _statsMap[player.userId]!.totals = updatedTotals;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Add Stats for ${widget.event.title}'),
          actions: [
            IconButton(
                icon: Icon(Icons.save),
                onPressed: _isLoading ? null : _saveAllStats)
          ]),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (widget.event.eventType == 'match')
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                        controller: _opponentScoreController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            labelText: 'Opponent Score',
                            border: OutlineInputBorder())),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.participants.length,
                    itemBuilder: (context, index) {
                      final player = widget.participants[index];
                      // Use the correct userId for the map key
                      final playerStats = _statsMap[player.userId]!.totals;
                      return ListTile(
                        title: Text(player.name ?? 'Unknown Player'),
                        subtitle: Text(
                            'PTS: ${playerStats.pts}, REB: ${playerStats.reb}, AST: ${playerStats.ast}'),
                        trailing: Icon(Icons.edit),
                        onTap: () => _editStatsForPlayer(player),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

// --- The _EditPlayerStatsForm widget remains here, unchanged ---
class _EditPlayerStatsForm extends StatefulWidget {
  final User player;
  final StatSet initialStats;
  final ValueChanged<StatSet> onSave;

  const _EditPlayerStatsForm(
      {Key? key,
      required this.player,
      required this.initialStats,
      required this.onSave})
      : super(key: key);

  @override
  __EditPlayerStatsFormState createState() => __EditPlayerStatsFormState();
}

class __EditPlayerStatsFormState extends State<_EditPlayerStatsForm> {
  final _formKey = GlobalKey<FormState>();
  late StatSet _currentStats;
  late Map<String, TextEditingController> _controllers;
  int _calculatedPoints = 0;

  @override
  void initState() {
    super.initState();
    _currentStats = StatSet.fromMap(widget.initialStats.toMap());
    _controllers = {
      'mp': TextEditingController(text: _currentStats.mp.toStringAsFixed(1)),
      'orb': TextEditingController(text: _currentStats.orb.toString()),
      'drb': TextEditingController(text: _currentStats.drb.toString()),
      'ast': TextEditingController(text: _currentStats.ast.toString()),
      'stl': TextEditingController(text: _currentStats.stl.toString()),
      'blk': TextEditingController(text: _currentStats.blk.toString()),
      'tov': TextEditingController(text: _currentStats.tov.toString()),
      'fgm2': TextEditingController(text: _currentStats.fgm2.toString()),
      'fga2': TextEditingController(text: _currentStats.fga2.toString()),
      'fgm3': TextEditingController(text: _currentStats.fgm3.toString()),
      'fga3': TextEditingController(text: _currentStats.fga3.toString()),
      'ftm': TextEditingController(text: _currentStats.ftm.toString()),
      'fta': TextEditingController(text: _currentStats.fta.toString()),
    };
    _controllers['fgm2']!.addListener(_updateCalculatedPoints);
    _controllers['fgm3']!.addListener(_updateCalculatedPoints);
    _controllers['ftm']!.addListener(_updateCalculatedPoints);
    _updateCalculatedPoints();
  }

  void _updateCalculatedPoints() {
    final fgm2 = int.tryParse(_controllers['fgm2']!.text) ?? 0;
    final fgm3 = int.tryParse(_controllers['fgm3']!.text) ?? 0;
    final ftm = int.tryParse(_controllers['ftm']!.text) ?? 0;
    setState(() => _calculatedPoints = (fgm2 * 2) + (fgm3 * 3) + ftm);
  }

  @override
  void dispose() {
    _controllers.values.forEach((c) {
      c.removeListener(_updateCalculatedPoints);
      c.dispose();
    });
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _currentStats.pts = _calculatedPoints;
      _currentStats.reb = _currentStats.orb + _currentStats.drb;
      _currentStats.fgm = _currentStats.fgm2 + _currentStats.fgm3;
      _currentStats.fga = _currentStats.fga2 + _currentStats.fga3;
      widget.onSave(_currentStats);
      Navigator.of(context).pop();
    }
  }

  Widget _buildStatField(String label, String statKey,
      {String? unit, String? helper}) {
    final controller = _controllers[statKey]!;
    return TextFormField(
      controller: controller,
      onTap: () => controller.selection =
          TextSelection(baseOffset: 0, extentOffset: controller.text.length),
      decoration: InputDecoration(
          labelText: label,
          suffixText: unit,
          helperText: helper,
          helperStyle: TextStyle(color: Colors.grey[400])),
      keyboardType: TextInputType.numberWithOptions(decimal: statKey == 'mp'),
      validator: (value) => (value == null || double.tryParse(value) == null)
          ? 'Enter a valid number'
          : null,
      onSaved: (value) {
        final doubleValue = double.parse(value!);
        final intValue = doubleValue.toInt();
        switch (statKey) {
          case 'mp':
            _currentStats.mp = doubleValue;
            break;
          case 'orb':
            _currentStats.orb = intValue;
            break;
          case 'drb':
            _currentStats.drb = intValue;
            break;
          case 'ast':
            _currentStats.ast = intValue;
            break;
          case 'stl':
            _currentStats.stl = intValue;
            break;
          case 'blk':
            _currentStats.blk = intValue;
            break;
          case 'tov':
            _currentStats.tov = intValue;
            break;
          case 'fgm2':
            _currentStats.fgm2 = intValue;
            break;
          case 'fga2':
            _currentStats.fga2 = intValue;
            break;
          case 'fgm3':
            _currentStats.fgm3 = intValue;
            break;
          case 'fga3':
            _currentStats.fga3 = intValue;
            break;
          case 'ftm':
            _currentStats.ftm = intValue;
            break;
          case 'fta':
            _currentStats.fta = intValue;
            break;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('Edit Stats for ${widget.player.name}'),
          actions: [IconButton(icon: Icon(Icons.check), onPressed: _onSave)]),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Text('Total Points',
                        style: TextStyle(color: Colors.grey[400])),
                    Text('$_calculatedPoints',
                        style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange)),
                  ],
                ),
              ),
              SizedBox(height: 16),
              _buildStatField('Minutes Played', 'mp', unit: 'min'),
              SizedBox(height: 24),
              Text('Core Stats', style: Theme.of(context).textTheme.titleLarge),
              Row(children: [
                Expanded(child: _buildStatField('Offensive Rebounds', 'orb')),
                SizedBox(width: 16),
                Expanded(child: _buildStatField('Defensive Rebounds', 'drb'))
              ]),
              _buildStatField('Assists', 'ast'),
              _buildStatField('Steals', 'stl'),
              _buildStatField('Blocks', 'blk'),
              _buildStatField('Turnovers', 'tov'),
              SizedBox(height: 24),
              Text('Shooting', style: Theme.of(context).textTheme.titleLarge),
              Row(children: [
                Expanded(
                    child: _buildStatField('2-Pointers Made', 'fgm2',
                        helper: 'Made')),
                SizedBox(width: 16),
                Expanded(
                    child: _buildStatField('2-Pointers Attempted', 'fga2',
                        helper: 'Attempted'))
              ]),
              SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _buildStatField('3-Pointers Made', 'fgm3',
                        helper: 'Made')),
                SizedBox(width: 16),
                Expanded(
                    child: _buildStatField('3-Pointers Attempted', 'fga3',
                        helper: 'Attempted'))
              ]),
              SizedBox(height: 16),
              Row(children: [
                Expanded(
                    child: _buildStatField('Free Throws Made', 'ftm',
                        helper: 'Made')),
                SizedBox(width: 16),
                Expanded(
                    child: _buildStatField('Free Throws Attempted', 'fta',
                        helper: 'Attempted'))
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
