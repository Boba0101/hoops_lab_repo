import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

//providers
import 'providers/app_navigation_state.dart';

// Screens
import 'screens/coach_home_screen.dart';
import 'screens/player_home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/match_history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/player_profile_setup_screen.dart';
import 'screens/coach_profile_setup_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/team_dashboard_screen.dart';

// Services and Models
import 'services/firebase_service.dart';
import 'services/auth_service.dart';
import 'services/ai_service.dart';
import 'models/user.dart' as app_user;

void main() async {
  // This line MUST be here, and it must be the FIRST line.
  WidgetsFlutterBinding.ensureInitialized();

  // This is the ONLY place we initialize Firebase.
  // The FirebaseService.initialize() method has a safety check
  // to prevent it from running more than once.
  await FirebaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppNavigationState()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirebaseService>(create: (_) => FirebaseService()),
        Provider<AIService>(create: (_) => AIService()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Color(0xFF121212),
        colorScheme: ColorScheme.dark().copyWith(
          secondary: Colors.orange,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => AuthWrapper(),
        '/home': (context) => HoopsLabHome(),
        '/settings': (context) => SettingsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<fb_auth.User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user == null) {
            return LoginScreen();
          }
          // User is authenticated, check their profile status
          return ProfileCheckWrapper(user: user);
        }
        return Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.orange)),
        );
      },
    );
  }
}

// UPDATED: This widget now directs users to the correct profile setup screen
class ProfileCheckWrapper extends StatelessWidget {
  final fb_auth.User user;

  const ProfileCheckWrapper({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebaseService = Provider.of<FirebaseService>(context);

    return FutureBuilder<app_user.User?>(
      // Fetch the user document from Firestore
      future: firebaseService.getUserById(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Loading your profile...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          // Handle cases where the user document doesn't exist in Firestore
          // (e.g., sign-up failed halfway)
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text('Error loading your profile data.'),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        Provider.of<AuthService>(context, listen: false)
                            .signOut(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    child: Text('Return to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        final appUser = snapshot.data!;

        // --- CORE NAVIGATION LOGIC ---
        if (appUser.profileCompleted) {
          // If profile is complete, let them into the main app
          print('ProfileCheckWrapper: Profile complete. Entering main app.');
          return HoopsLabHome();
        } else {
          // If profile is NOT complete, route based on role
          print(
              'ProfileCheckWrapper: Profile incomplete. Routing to setup screen for role: ${appUser.role}');
          if (appUser.role == 'Player') {
            return PlayerProfileSetupScreen();
          } else if (appUser.role == 'Coach') {
            return CoachProfileSetupScreen(); // NEW NAVIGATION
          } else {
            // Fallback for an unknown role
            return Scaffold(
              body: Center(
                child: Text('Unknown user role. Please contact support.'),
              ),
            );
          }
        }
      },
    );
  }
}

// --- MAIN APP SHELL (NO CHANGES BELOW THIS LINE) ---
// Note: We will refactor HoopsLabHome and AuthAwareHomeScreen in the next step
// to show role-specific content. The navigation logic above is the key change for now.

class HoopsLabHome extends StatefulWidget {
  @override
  _HoopsLabHomeState createState() => _HoopsLabHomeState();
}

class _HoopsLabHomeState extends State<HoopsLabHome> {
  // The _selectedIndex is now managed by the provider, so we can remove it from this local state.

  final List<Widget> _screens = [
    TeamDashboardScreen(),
    ScheduleScreen(),
    AuthAwareHomeScreen(),
    MatchHistoryScreen(),
    Container(), // Placeholder for the 'More' options
  ];

  // The _onItemTapped and _showMoreOptions methods will now use the provider
  void _onItemTapped(int index, AppNavigationState navState) {
    if (index == 4) {
      _showMoreOptions();
    } else {
      navState.goToTab(index);
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        // Get the AuthService instance using Provider
        final authService = Provider.of<AuthService>(context, listen: false);

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.settings, color: Colors.orange),
                title: Text("Settings"),
                onTap: () {
                  // First, pop the bottom sheet
                  Navigator.pop(context);
                  // Then, navigate to our new settings screen
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              Divider(color: Colors.grey[800]),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.orange),
                title: Text("Sign Out"),
                onTap: () async {
                  // 1. Close the bottom sheet first for a smooth UX
                  Navigator.pop(context);

                  // 2. Call the signOut method from your AuthService
                  await authService.signOut();

                  // 3. No need for Navigator.pushReplacement() here!
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // We use a Consumer to listen for changes in the AppNavigationState
    return Consumer<AppNavigationState>(
      builder: (context, navState, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              [
                'Dashboard',
                'Schedule',
                'Home',
                'History',
                'More'
              ][navState.selectedIndex],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Text('🤖', style: TextStyle(fontSize: 24)),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => ChatScreen())),
              )
            ],
          ),
          body: IndexedStack(
            index: navState.selectedIndex, // Get the index from the provider
            children: _screens,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today), label: 'Schedule'),
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.history), label: 'History'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.more_horiz), label: 'More'),
            ],
            currentIndex:
                navState.selectedIndex, // Get the index from the provider
            selectedItemColor: Colors.orange,
            unselectedItemColor: Colors.white70,
            onTap: (index) =>
                _onItemTapped(index, navState), // Update the provider on tap
            type: BottomNavigationBarType.fixed,
            backgroundColor: Color(0xFF1E1E1E),
          ),
        );
      },
    );
  }
}

class AuthAwareHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    // This FutureBuilder is the key to showing the correct screen.
    // It fetches the user's data from Firestore to determine their role.
    return FutureBuilder<app_user.User?>(
      future: firebaseService.getUserById(authService.currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Center(
            child: Text(
              'Could not load user data.\nPlease try signing out and in again.',
              textAlign: TextAlign.center,
            ),
          );
        }

        final appUser = snapshot.data!;

        // Based on the user's role, return the appropriate home screen widget
        if (appUser.role == 'Coach') {
          return CoachHomeScreen();
        } else {
          return PlayerHomeScreen();
        }
      },
    );
  }
}
