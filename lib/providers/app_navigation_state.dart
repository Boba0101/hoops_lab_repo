// lib/providers/app_navigation_state.dart

import 'package:flutter/foundation.dart';

class AppNavigationState with ChangeNotifier {
  int _selectedIndex = 2; // Default to the 'Home' tab (index 2)

  int get selectedIndex => _selectedIndex;

  void goToTab(int index) {
    _selectedIndex = index;
    notifyListeners(); // This is what tells the UI to rebuild
  }
}
