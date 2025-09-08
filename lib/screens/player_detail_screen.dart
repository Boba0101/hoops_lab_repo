import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';

class PlayerDetailScreen extends StatelessWidget {
  // This screen receives a User object, it doesn't fetch its own data.
  final User player;

  const PlayerDetailScreen({Key? key, required this.player}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(player.name ?? 'Player Details'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildProfileCard(context),
            SizedBox(height: 16),
            // You could add more cards here later for stats, performance logs, etc.
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
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
            Divider(height: 24),
            _buildStatRow(context, Icons.email, 'Email', player.email),
            _buildStatRow(
              context,
              Icons.date_range,
              'Joined',
              DateFormat('MMMM d, yyyy')
                  .format(player.createdAt), // Format the date
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for displaying a single row of information.
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
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
