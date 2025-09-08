import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      if (userCredential.user != null) {
        final firebaseService = FirebaseService();
        try {
          await firebaseService.updateLastLogin(userCredential.user!.uid);
        } catch (e) {
          print('Warning: Could not update last login: $e');
        }
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // COMPLETELY REWRITTEN - Sign up with email and password
  Future<UserCredential> signUpWithEmail(
      String email, String password, String role) async {
    UserCredential? userCredential;

    try {
      print('Starting sign up process for email: $email with role: $role');

      // Step 1: Create Firebase Auth user
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception(
            'Failed to create user - no user returned from Firebase Auth');
      }

      print('Firebase Auth user created successfully: ${user.uid}');

      // Step 2: Create user document in Firestore
      await _createUserDocument(user, email, role);

      print('User document created successfully in Firestore');
      return userCredential;
    } catch (e) {
      print('ERROR in signUpWithEmail: $e');
      print('Error type: ${e.runtimeType}');

      // Clean up Firebase Auth user if Firestore operation failed
      if (userCredential?.user != null) {
        try {
          print('Attempting to clean up Firebase Auth user...');
          await userCredential!.user!.delete();
          print('Firebase Auth user cleaned up successfully');
        } catch (cleanupError) {
          print('Failed to clean up Firebase Auth user: $cleanupError');
        }
      }

      throw _handleAuthException(e);
    }
  }

  // SEPARATE METHOD: Create user document in Firestore
  Future<void> _createUserDocument(
      User firebaseUser, String email, String role) async {
    try {
      print('Creating user document for: ${firebaseUser.uid}');

      final appUser = app_user.User(
        id: firebaseUser.uid,
        email: email,
        role: role,
        createdAt: DateTime.now(),
        // THE FIX: A new user's profile is NEVER complete by default.
        // The setup screen is responsible for setting this to true later.
        profileCompleted: false,
      );

      print('User object created: ${appUser.toMap()}');

      final firebaseService = FirebaseService();

      // Try to save user with multiple attempts
      await _saveUserWithRetry(firebaseService, appUser);

      print('User document saved successfully');
    } catch (e) {
      print('ERROR creating user document: $e');
      rethrow;
    }
  }

  // SEPARATE METHOD: Save user with retry logic
  Future<void> _saveUserWithRetry(
      FirebaseService firebaseService, app_user.User user) async {
    const maxAttempts = 3;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        print('Saving user document - attempt $attempt/$maxAttempts');
        await firebaseService.saveUser(user);
        print('User document saved on attempt $attempt');
        return; // Success - exit the retry loop
      } catch (e) {
        print('Save attempt $attempt failed: $e');

        if (attempt == maxAttempts) {
          print('All save attempts failed');
          rethrow; // Final attempt failed
        }

        // Wait before retrying (exponential backoff)
        final delayMs = 1000 * attempt; // 1s, 2s, 3s
        print('Waiting ${delayMs}ms before retry...');
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error during sign out: $e');
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // IMPROVED: Handle Firebase Auth exceptions with user-friendly messages
  String _handleAuthException(dynamic e) {
    print('Handling auth exception: $e');
    print('Exception type: ${e.runtimeType}');

    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'Email is already in use.';
        case 'invalid-email':
          return 'Email address is invalid.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'operation-not-allowed':
          return 'Operation not allowed.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        default:
          return 'Authentication error: ${e.message ?? e.code}';
      }
    }

    // Handle other types of exceptions
    if (e.toString().contains('permission-denied')) {
      return 'Permission denied. Please check your account settings.';
    }

    if (e.toString().contains('network')) {
      return 'Network error. Please check your internet connection.';
    }

    return 'An error occurred: ${e.toString()}';
  }

  // Get current user's role
  Future<String?> getCurrentUserRole() async {
    if (currentUser != null) {
      try {
        final firebaseService = FirebaseService();
        final user = await firebaseService.getUserById(currentUser!.uid);
        return user?.role;
      } catch (e) {
        print('Error getting user role: $e');
        return null;
      }
    }
    return null;
  }

  // Get current user's app user data
  Future<app_user.User?> getCurrentAppUser() async {
    if (currentUser != null) {
      try {
        final firebaseService = FirebaseService();
        return await firebaseService.getUserById(currentUser!.uid);
      } catch (e) {
        print('Error getting current app user: $e');
        return null;
      }
    }
    return null;
  }
}
