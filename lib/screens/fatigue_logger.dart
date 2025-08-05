// // fatigue_logger.dart
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/player.dart';
// import '../services/firebase_service.dart';

// class FatigueLogger extends StatefulWidget {
//   @override
//   _FatigueLoggerState createState() => _FatigueLoggerState();
// }

// class _FatigueLoggerState extends State<FatigueLogger> {
//   final FirebaseService _firebaseService = FirebaseService();
//   List<Player> _players = [];
//   Player? _selectedPlayer;
//   String?
//       _selectedPlayerId; // Add this variable to store the selected player ID
//   int _fatigueLevel = 5;
//   int _minutesPlayed = 30;
//   String? _notes;
//   bool _isLoading = true;
//   bool _mounted = true; // Track mounted state

//   @override
//   void initState() {
//     super.initState();
//     _loadPlayers();
//   }

//   @override
//   void dispose() {
//     _mounted = false; // Mark as unmounted
//     super.dispose();
//   }

//   Future<void> _loadPlayers() async {
//     try {
//       _firebaseService.getPlayers().listen(
//         (players) {
//           if (_mounted) {
//             // Check if still mounted
//             setState(() {
//               _players = players;
//               _isLoading = false;
//             });
//           }
//         },
//         onError: (e) {
//           print('Error loading players: $e');
//           if (_mounted) {
//             // Check if still mounted
//             setState(() {
//               _isLoading = false;
//             });
//           }
//         },
//       );
//     } catch (e) {
//       print('Error loading players: $e');
//       if (_mounted) {
//         // Check if still mounted
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   Future<void> _saveFatigueData() async {
//     if (_selectedPlayer == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Please select a player')),
//       );
//       return;
//     }

//     final fatigueData = FatigueData(
//       date: DateTime.now(),
//       fatigueLevel: _fatigueLevel,
//       minutesPlayed: _minutesPlayed,
//       notes: _notes,
//     );

//     try {
//       await _firebaseService.addFatigueData(
//         _selectedPlayer!.id,
//         fatigueData,
//       );

//       if (_mounted) {
//         // Check if still mounted
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Fatigue data saved successfully')),
//         );
//         Navigator.pop(context);
//       }
//     } catch (e) {
//       if (_mounted) {
//         // Check if still mounted
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to save fatigue data: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Fatigue Logger',
//             style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   if (_players.isEmpty)
//                     Card(
//                       child: Padding(
//                         padding: EdgeInsets.all(16),
//                         child: Text('No players available. Add players first.'),
//                       ),
//                     )
//                   else
//                     _buildPlayerSelector(),
//                   SizedBox(height: 20),
//                   if (_players.isNotEmpty) ...[
//                     Text(
//                       "How tired is ${_selectedPlayer?.name ?? 'the player'} feeling?",
//                       style: TextStyle(fontSize: 16),
//                       textAlign: TextAlign.center,
//                     ),
//                     SizedBox(height: 10),
//                     Text(
//                       "Fatigue Level: $_fatigueLevel (${_getFatigueDescription(_fatigueLevel)})",
//                       style:
//                           TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     Slider(
//                       value: _fatigueLevel.toDouble(),
//                       min: 1,
//                       max: 10,
//                       divisions: 9,
//                       label: _fatigueLevel.toString(),
//                       onChanged: (value) {
//                         // Don't trigger a full rebuild if the value hasn't changed
//                         if (_fatigueLevel != value.toInt()) {
//                           setState(() {
//                             _fatigueLevel = value.toInt();
//                           });
//                         }
//                       },
//                     ),
//                     SizedBox(height: 20),
//                     Text(
//                       "Minutes Played: $_minutesPlayed",
//                       style:
//                           TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     Slider(
//                       value: _minutesPlayed.toDouble(),
//                       min: 0,
//                       max: 48,
//                       divisions: 48,
//                       label: _minutesPlayed.toString(),
//                       onChanged: (value) {
//                         setState(() {
//                           _minutesPlayed = value.toInt();
//                         });
//                       },
//                     ),
//                     SizedBox(height: 20),
//                     TextField(
//                       decoration: InputDecoration(
//                         labelText: 'Additional Notes (optional)',
//                         border: OutlineInputBorder(),
//                       ),
//                       maxLines: 2,
//                       onChanged: (value) => _notes = value,
//                     ),
//                     SizedBox(height: 30),
//                     ElevatedButton(
//                       onPressed: _saveFatigueData,
//                       child: Text("Save Fatigue Data"),
//                       style: ElevatedButton.styleFrom(
//                         minimumSize: Size(double.infinity, 50),
//                         backgroundColor: Colors.orange,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _buildPlayerSelector() {
//     return Card(
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Select Player',
//                 style: TextStyle(fontWeight: FontWeight.bold)),
//             SizedBox(height: 10),
//             DropdownButtonFormField<String>(
//               value: _selectedPlayerId,
//               hint: Text('Choose a player'),
//               items: _players.map((player) {
//                 return DropdownMenuItem<String>(
//                   value: player.id,
//                   child: Text(player.name),
//                 );
//               }).toList(),
//               onChanged: (playerId) {
//                 setState(() {
//                   _selectedPlayerId = playerId;
//                   _selectedPlayer =
//                       _players.firstWhere((p) => p.id == playerId);
//                 });
//               },
//               decoration: InputDecoration(
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _getFatigueDescription(int level) {
//     if (level <= 3) return 'Fresh';
//     if (level <= 5) return 'Moderate';
//     if (level <= 7) return 'Tired';
//     if (level <= 9) return 'Very Tired';
//     return 'Exhausted';
//   }
// }
