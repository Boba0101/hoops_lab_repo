import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // We use a FutureBuilder to get the most up-to-date user data
    // before allowing them to edit it.
    final authService = Provider.of<AuthService>(context, listen: false);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<User?>(
        future: firebaseService.getUserById(authService.currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: Colors.orange));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('Could not load user profile.'));
          }

          final currentUser = snapshot.data!;

          return ListView(
            children: [
              ListTile(
                leading: Icon(Icons.person, color: Colors.orange),
                title: Text('Edit Profile'),
                subtitle: Text('Update your personal information'),
                onTap: () {
                  // Navigate to the EditProfileScreen, passing the current user data
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditProfileScreen(user: currentUser),
                    ),
                  );
                },
              ),
              Divider(),
              // You can add more settings options here in the future
              // e.g., ListTile for "Change Password", etc.
            ],
          );
        },
      ),
    );
  }
}
