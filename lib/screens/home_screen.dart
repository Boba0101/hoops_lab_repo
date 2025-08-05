import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/player.dart';
import '../services/firebase_service.dart';
import 'add_player_screen.dart';
import 'edit_player_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Player> players = [];
  bool _isLoading = true;

  final NextGame nextGame = NextGame(
    opponent: 'Los Angeles Lakers',
    date: DateTime.now().add(Duration(days: 2)),
    location: 'Staples Center',
    isHome: false,
  );

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
    });

    _firebaseService.getPlayers().listen((playersList) {
      setState(() {
        players = playersList;
        _isLoading = false;
      });
    }, onError: (error) {
      print('Error loading players: $error');
      setState(() {
        _isLoading = false;
      });
    });
  }

  void _navigateToEditPlayer(Player player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPlayerScreen(
          player: player,
          onPlayerUpdated: (updatedPlayer) {
            // Player will be updated in Firestore and reflected in our stream
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('${updatedPlayer.name} updated successfully')),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mvp = players.isNotEmpty
        ? players.first
        : Player(
            id: '1',
            name: 'No Players',
            height: 0,
            weight: 0,
            age: 0,
            team: 'N/A',
            position: 'N/A',
          );

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPlayerScreen(
                onPlayerAdded: (newPlayer) {
                  // Player will be added to Firestore and automatically reflected in our stream
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${newPlayer.name} added successfully')),
                  );
                },
              ),
            ),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Team Dashboard',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                  SizedBox(height: 20),
                  _buildTeamStatsCard(context),
                  SizedBox(height: 16),
                  Text('Last Game MVP',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  SizedBox(height: 16),
                  _buildMVPCard(context, mvp),
                  SizedBox(height: 16),
                  Text('Next Game',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  SizedBox(height: 8),
                  _buildNextGameCard(context),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Player Roster',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  )),
                      Text('Tap player to edit',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey,
                                  )),
                    ],
                  ),
                  SizedBox(height: 8),
                  _buildPlayerList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTeamStatsCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Season Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    )),
                Chip(
                  label: Text('12-5'),
                  backgroundColor: Colors.green.withOpacity(0.2),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                //season stats
                _buildStatItem(context, '112.4', 'PPG'),
                _buildStatItem(context, '45.2%', 'FG%'),
                _buildStatItem(context, '38.7%', '3P%'),
                _buildStatItem(context, '4', 'Streak'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                )),
        SizedBox(height: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                )),
      ],
    );
  }

  Widget _buildMVPCard(BuildContext context, Player mvp) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[200],
              child: mvp.name == 'No Players'
                  ? Icon(Icons.person, size: 30)
                  : null,
              backgroundImage: _getPlayerImage(mvp),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mvp.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                SizedBox(height: 6),
                Text('Height: ${mvp.height} cm, Weight: ${mvp.weight} kg,',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text('Age: ${mvp.age}',
                    style: Theme.of(context).textTheme.bodyLarge),
                Text('Team: ${mvp.team}, Position: ${mvp.position}',
                    style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            if (mvp.name != 'No Players') SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  ImageProvider? _getPlayerImage(Player player) {
    if (player.imageBase64 != null) {
      return MemoryImage(base64Decode(player.imageBase64!));
    }
    return null;
  }

  Widget _buildStatChip(String value, String label) {
    return Chip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              )),
          Text(label,
              style: TextStyle(
                fontSize: 10,
              )),
        ],
      ),
      backgroundColor: Colors.grey.withOpacity(0.1),
    );
  }

  Widget _buildNextGameCard(BuildContext context) {
    final formatter = DateFormat('EEE, MMM d • h:mm a');
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    nextGame.isHome
                        ? 'VS ${nextGame.opponent}'
                        : '@ ${nextGame.opponent}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        )),
                Chip(
                  label: Text(nextGame.isHome ? 'HOME' : 'AWAY'),
                  backgroundColor: nextGame.isHome
                      ? Colors.green.withOpacity(0.2)
                      : Colors.blue.withOpacity(0.2),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(formatter.format(nextGame.date)),
                SizedBox(width: 16),
                Icon(Icons.location_on, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(nextGame.location),
              ],
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.85,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Win Probability: 85%',
                    style: TextStyle(color: Colors.green)),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Prepare', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerList() {
    if (players.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No players added yet. Tap + to add players.',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return Dismissible(
          key: Key(player.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(right: 20),
            child: Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Delete Player'),
                content:
                    Text('Are you sure you want to delete ${player.name}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Delete'),
                  ),
                ],
              ),
            );
          },
          onDismissed: (direction) {
            _firebaseService.deletePlayer(player.id);
          },
          child: Card(
            margin: EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: _getPlayerImage(player),
                child: player.imageBase64 == null ? Icon(Icons.person) : null,
              ),
              title: Text(player.name),
              subtitle: Text(
                  'Height: ${player.height} cm | Weight: ${player.weight} kg | Age: ${player.age}'),
              trailing: Icon(Icons.edit, color: Colors.orange),
              onTap: () => _navigateToEditPlayer(player),
            ),
          ),
        );
      },
    );
  }
}

class NextGame {
  final String opponent;
  final DateTime date;
  final String location;
  final bool isHome;

  NextGame({
    required this.opponent,
    required this.date,
    required this.location,
    required this.isHome,
  });
}
