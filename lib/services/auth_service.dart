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
        await firebaseService.updateLastLogin(userCredential.user!.uid);
      }

      return userCredential;
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign up with email and password
  Future<UserCredential> signUpWithEmail(
      String email, String password, String role) async {
    try {
      print('Starting sign up process for email: $email with role: $role');

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print(
          'Firebase Auth user created successfully: ${userCredential.user?.uid}');

      // Create and save user data to Firestore
      if (userCredential.user != null) {
        print('Creating user data for Firestore...');

        final user = app_user.User(
          id: userCredential.user!.uid,
          email: email,
          role: role,
          createdAt: DateTime.now(),
        );

        print('User object created: ${user.toMap()}');

        final firebaseService = FirebaseService();
        print('Saving user to Firestore...');
        await firebaseService.saveUser(user);
        print('User saved to Firestore successfully!');

        // REMOVED THE TEST RETRIEVAL CALL THAT CAUSED THE ERROR
      } else {
        print('ERROR: userCredential.user is null!');
      }

      return userCredential;
    } catch (e) {
      print('ERROR in signUpWithEmail: $e');
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Then sign out
      await _auth.signOut();
    } catch (e) {
      print('Error during sign out: $e');
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

  // Handle Firebase Auth exceptions with user-friendly messages
  String _handleAuthException(dynamic e) {
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
        default:
          return 'Authentication error: ${e.message}';
      }
    }
    return 'An unknown error occurred.';
  }

  // Get current user's role
  Future<String?> getCurrentUserRole() async {
    if (currentUser != null) {
      final firebaseService = FirebaseService();
      final user = await firebaseService.getUserById(currentUser!.uid);
      return user?.role;
    }
    return null;
  }
}
