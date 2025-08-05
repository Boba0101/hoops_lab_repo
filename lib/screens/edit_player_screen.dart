// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import '../models/player.dart';
// import '../services/firebase_service.dart';
// import 'package:firebase_storage/firebase_storage.dart';

// class EditPlayerScreen extends StatefulWidget {
//   final Player player;
//   final Function(Player)? onPlayerUpdated;

//   const EditPlayerScreen({
//     Key? key,
//     required this.player,
//     this.onPlayerUpdated,
//   }) : super(key: key);

//   @override
//   _EditPlayerScreenState createState() => _EditPlayerScreenState();
// }

// class _EditPlayerScreenState extends State<EditPlayerScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _nameController;
//   late TextEditingController _pointsController;
//   late TextEditingController _reboundsController;
//   late TextEditingController _assistsController;
//   late TextEditingController _fgController;

//   File? _imageFile;
//   final ImagePicker _picker = ImagePicker();
//   final FirebaseService _firebaseService = FirebaseService();
//   bool _isLoading = false;
//   bool _imageChanged = false;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize controllers with existing player data
//     _nameController = TextEditingController(text: widget.player.name);
//     _pointsController =
//         TextEditingController(text: widget.player.points.toString());
//     _reboundsController =
//         TextEditingController(text: widget.player.rebounds.toString());
//     _assistsController =
//         TextEditingController(text: widget.player.assists.toString());
//     _fgController =
//         TextEditingController(text: widget.player.fgPercentage.toString());
//   }

//   Future<void> _getImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

//     if (pickedFile != null) {
//       setState(() {
//         _imageFile = File(pickedFile.path);
//         _imageChanged = true;
//       });
//     }
//   }

//   Future<String?> _uploadImage(String playerId) async {
//     if (_imageFile == null) return null;

//     try {
//       // Create a reference to the player's image in Firebase Storage
//       final storageRef = FirebaseStorage.instance
//           .ref()
//           .child('player_images')
//           .child('${playerId}.jpg');

//       // Show upload progress or message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Uploading image...')),
//       );

//       // Set metadata to ensure proper content type
//       final metadata = SettableMetadata(
//         contentType: 'image/jpeg',
//       );

//       // Upload the file with metadata
//       await storageRef.putFile(_imageFile!, metadata);

//       // Get download URL
//       final url = await storageRef.getDownloadURL();

//       return url;
//     } catch (e) {
//       print('Error uploading image: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Image upload failed: ${e.toString()}')),
//       );
//       // Return null so the player can still be saved without an image
//       return null;
//     }
//   }

//   Future<void> _submitForm() async {
//     if (_formKey.currentState!.validate()) {
//       setState(() {
//         _isLoading = true;
//       });

//       try {
//         String? imageUrl = await _uploadImage(widget.player.id);

//         final updatedPlayer = Player(
//           id: widget.player.id, // Keep the same ID
//           name: _nameController.text,
//           points: double.parse(_pointsController.text),
//           rebounds: double.parse(_reboundsController.text),
//           assists: double.parse(_assistsController.text),
//           fgPercentage: double.parse(_fgController.text),
//           imageUrl: imageUrl,
//           imagePath: _imageChanged ? _imageFile?.path : widget.player.imagePath,
//         );

//         // Save to Firebase
//         await _firebaseService.savePlayer(updatedPlayer);

//         // Notify parent widget if callback is provided
//         if (widget.onPlayerUpdated != null) {
//           widget.onPlayerUpdated!(updatedPlayer);
//         }

//         // Show success message and pop back
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Player updated successfully')),
//         );
//         Navigator.pop(context);
//       } catch (e) {
//         print('Error updating player: $e');
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error updating player. Please try again.')),
//         );
//       } finally {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Edit Player'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.save),
//             onPressed: _isLoading ? null : _submitForm,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: EdgeInsets.all(16),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     GestureDetector(
//                       onTap: _getImage,
//                       child: CircleAvatar(
//                         radius: 50,
//                         backgroundColor: Colors.grey[200],
//                         backgroundImage: _getPlayerImage(),
//                         child: _getPlayerImage() == null
//                             ? Icon(Icons.add_a_photo,
//                                 size: 40, color: Colors.grey)
//                             : null,
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     TextFormField(
//                       controller: _nameController,
//                       decoration: InputDecoration(
//                         labelText: 'Player Name',
//                         border: OutlineInputBorder(),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter player name';
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextFormField(
//                             controller: _pointsController,
//                             decoration: InputDecoration(
//                               labelText: 'PPG',
//                               border: OutlineInputBorder(),
//                             ),
//                             keyboardType:
//                                 TextInputType.numberWithOptions(decimal: true),
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Enter points';
//                               }
//                               if (double.tryParse(value) == null) {
//                                 return 'Enter valid number';
//                               }
//                               return null;
//                             },
//                           ),
//                         ),
//                         SizedBox(width: 16),
//                         Expanded(
//                           child: TextFormField(
//                             controller: _reboundsController,
//                             decoration: InputDecoration(
//                               labelText: 'RPG',
//                               border: OutlineInputBorder(),
//                             ),
//                             keyboardType:
//                                 TextInputType.numberWithOptions(decimal: true),
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Enter rebounds';
//                               }
//                               if (double.tryParse(value) == null) {
//                                 return 'Enter valid number';
//                               }
//                               return null;
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 16),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextFormField(
//                             controller: _assistsController,
//                             decoration: InputDecoration(
//                               labelText: 'APG',
//                               border: OutlineInputBorder(),
//                             ),
//                             keyboardType:
//                                 TextInputType.numberWithOptions(decimal: true),
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Enter assists';
//                               }
//                               if (double.tryParse(value) == null) {
//                                 return 'Enter valid number';
//                               }
//                               return null;
//                             },
//                           ),
//                         ),
//                         SizedBox(width: 16),
//                         Expanded(
//                           child: TextFormField(
//                             controller: _fgController,
//                             decoration: InputDecoration(
//                               labelText: 'FG%',
//                               border: OutlineInputBorder(),
//                               suffixText: '%',
//                             ),
//                             keyboardType:
//                                 TextInputType.numberWithOptions(decimal: true),
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Enter FG%';
//                               }
//                               if (double.tryParse(value) == null) {
//                                 return 'Enter valid number';
//                               }
//                               return null;
//                             },
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: 24),
//                     ElevatedButton(
//                       onPressed: _isLoading ? null : _submitForm,
//                       child: Text('Update Player',
//                           style: TextStyle(color: Colors.white)),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         minimumSize: Size(double.infinity, 50),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }

//   ImageProvider? _getPlayerImage() {
//     if (_imageFile != null) {
//       return FileImage(_imageFile!);
//     } else if (widget.player.imageUrl != null) {
//       return NetworkImage(widget.player.imageUrl!);
//     } else if (widget.player.imagePath != null) {
//       return FileImage(File(widget.player.imagePath!));
//     }
//     return null;
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _pointsController.dispose();
//     _reboundsController.dispose();
//     _assistsController.dispose();
//     _fgController.dispose();
//     super.dispose();
//   }
// }
import 'dart:convert'; // For Base64 encoding/decoding
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/player.dart';
import '../services/firebase_service.dart';

class EditPlayerScreen extends StatefulWidget {
  final Player player;
  final Function(Player)? onPlayerUpdated;

  const EditPlayerScreen({
    Key? key,
    required this.player,
    this.onPlayerUpdated,
  }) : super(key: key);

  @override
  _EditPlayerScreenState createState() => _EditPlayerScreenState();
}

class _EditPlayerScreenState extends State<EditPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;
  late TextEditingController _teamController;
  late TextEditingController _positionController;

  File? _imageFile;
  String? _imageBase64;
  final ImagePicker _picker = ImagePicker();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing player data
    _nameController = TextEditingController(text: widget.player.name);
    _heightController =
        TextEditingController(text: widget.player.height.toString());
    _weightController =
        TextEditingController(text: widget.player.weight.toString());
    _ageController = TextEditingController(text: widget.player.age.toString());
    _teamController = TextEditingController(text: widget.player.team);
    _positionController = TextEditingController(text: widget.player.position);
    _imageBase64 = widget.player.imageBase64;
  }

  Future<void> _getImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      setState(() {
        _imageFile = file;
        _imageBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updatedPlayer = Player(
          id: widget.player.id, // Keep the same ID
          name: _nameController.text,
          height: double.parse(_heightController.text),
          weight: double.parse(_weightController.text),
          age: int.parse(_ageController.text),
          team: _teamController.text,
          position: _positionController.text,
          imageBase64: _imageBase64,
        );

        // Save to Firebase
        await _firebaseService.savePlayer(updatedPlayer);

        // Notify parent widget if callback is provided
        if (widget.onPlayerUpdated != null) {
          widget.onPlayerUpdated!(updatedPlayer);
        }

        // Show success message and pop back
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Player updated successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        print('Error updating player: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating player. Please try again.')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Player'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _submitForm,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _getImage,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _getPlayerImage(),
                        child: _getPlayerImage() == null
                            ? Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey)
                            : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Player Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter player name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _heightController,
                      decoration: InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter height';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter weight';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter age';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _teamController,
                      decoration: InputDecoration(
                        labelText: 'Team',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter team';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _positionController,
                      decoration: InputDecoration(
                        labelText: 'Position',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter position';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitForm,
                      child: Text('Update Player',
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  ImageProvider? _getPlayerImage() {
    if (_imageFile != null) {
      return FileImage(_imageFile!);
    } else if (_imageBase64 != null) {
      return MemoryImage(base64Decode(_imageBase64!));
    }
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _teamController.dispose();
    _positionController.dispose();
    super.dispose();
  }
}
