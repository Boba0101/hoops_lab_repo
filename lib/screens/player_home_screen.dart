// lib/screens/player_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart' as app_user;
import '../services/auth_service.dart';
import '../services/firebase_service.dart';

class PlayerHomeScreen extends StatelessWidget {
  const PlayerHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      body: FutureBuilder<app_user.User?>(
        // Fetch the detailed user object from Firestore
        future: firebaseService.getUserById(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('Could not load your profile.'));
          }

          final player = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${player.name ?? 'Player'}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 8),
                Text(
                  'Here are your current profile stats. View the Dashboard tab for team updates.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[400],
                      ),
                ),
                SizedBox(height: 24),
                _buildProfileCard(context, player),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, app_user.User player) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Player Profile',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Divider(height: 24),
            _buildStatRow(context, Icons.person, 'Name', player.name ?? 'N/A'),
            _buildStatRow(
                context, Icons.cake, 'Age', '${player.age ?? 'N/A'} years'),
            _buildStatRow(context, Icons.wc, 'Gender', player.gender ?? 'N/A'),
            _buildStatRow(context, Icons.height, 'Height',
                '${player.height ?? 'N/A'} cm'),
            _buildStatRow(context, Icons.fitness_center, 'Weight',
                '${player.weight ?? 'N/A'} kg'),
            _buildStatRow(context, Icons.sports_basketball, 'Position',
                player.position ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          SizedBox(width: 16),
          Text(
            '$label:',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.grey[300]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
