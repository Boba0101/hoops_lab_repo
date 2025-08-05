import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/dashboard_screen.dart';
import 'screens/home_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/match_history_screen.dart';
import 'screens/login_screen.dart';
import 'services/firebase_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
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
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          return user != null ? HoopsLabHome() : LoginScreen();
        }

        // Show a loading indicator while waiting for the auth state
        return Scaffold(
          backgroundColor: Color(0xFF121212),
          body: Center(
            child: CircularProgressIndicator(color: Colors.orange),
          ),
        );
      },
    );
  }
}

class HoopsLabHome extends StatefulWidget {
  @override
  _HoopsLabHomeState createState() => _HoopsLabHomeState();
}

class _HoopsLabHomeState extends State<HoopsLabHome> {
  int _selectedIndex = 2;
  final List<Widget> _screens = [
    DashboardScreen(),
    ScheduleScreen(),
    HomeScreen(),
    MatchHistoryScreen(),
    Container(), // Placeholder for More screen
  ];

  void _onItemTapped(int index) {
    if (index == 4) {
      _showMoreOptions();
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
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
                onTap: () => Navigator.pop(context),
              ),
              Divider(color: Colors.grey[800]),
              ListTile(
                leading: Icon(Icons.logout, color: Colors.orange),
                title: Text("Sign Out"),
                onTap: () async {
                  Navigator.pop(context);
                  await Provider.of<AuthService>(context, listen: false)
                      .signOut();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.white70,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Color(0xFF1E1E1E),
          selectedFontSize: 12,
          unselectedFontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            [
              'Dashboard',
              'Schedule',
              'HoopsLab',
              'Stats',
              'More'
            ][_selectedIndex],
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: _selectedIndex == 2
            ? [
                IconButton(
                  icon: const Text(
                    '🤖',
                    style: TextStyle(fontSize: 24),
                  ),
                  onPressed: () {},
                )
              ]
            : null,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }
}
