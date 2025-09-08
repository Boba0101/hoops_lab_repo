import 'player_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart'; // UPDATED import
import '../services/firebase_service.dart';

class CoachHomeScreen extends StatelessWidget {
  const CoachHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      // The StreamBuilder will now listen to our new getPlayersStream method
      body: StreamBuilder<List<User>>(
        stream: firebaseService.getPlayersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No players have registered yet.',
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
            );
          }

          final players = snapshot.data!;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ... your Text widgets ...
                SizedBox(height: 16),
                _buildPlayerList(context, players), // Pass context here
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlayerList(BuildContext context, List<User> players) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.orange.withOpacity(0.2),
              child: Text(
                player.name?.substring(0, 1).toUpperCase() ?? 'P',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ),
            title: Text(player.name ?? 'Unnamed Player',
                style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${player.position ?? 'N/A'} | ${player.height?.toInt() ?? '-'} cm | ${player.weight?.toInt() ?? '-'} kg',
              style: TextStyle(color: Colors.grey[300]),
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey),

            // --- THE NAVIGATION LOGIC IS IMPLEMENTED HERE ---
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Navigate to the PlayerDetailScreen and pass the selected player object
                  builder: (context) => PlayerDetailScreen(player: player),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
