import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/player.dart';
import '../firebase_options.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Firebase Firestore instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get playersCollection => _db.collection('players');

  // Initialize Firebase
  // Check if Firebase initialization is successful by adding a print statement
  // In firebase_service.dart, modify the initialize method:
  static Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Enable persistence explicitly
        FirebaseFirestore.instance.settings = Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );

        print('Firebase initialized successfully with persistence');
      }
    } catch (e) {
      print('Firebase initialization error: $e');
    }
  }

  // Add or update a player
  Future<void> savePlayer(Player player) async {
    await playersCollection.doc(player.id).set(player.toMap());
  }

  // Get all players
  Stream<List<Player>> getPlayers() {
    return playersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Player.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get a single player by ID
  Future<Player?> getPlayerById(String id) async {
    DocumentSnapshot doc = await playersCollection.doc(id).get();
    if (doc.exists) {
      return Player.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Delete a player
  Future<void> deletePlayer(String id) async {
    await playersCollection.doc(id).delete();
  }

  //Fatigue data
}
