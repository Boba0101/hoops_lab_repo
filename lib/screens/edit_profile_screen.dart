import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';

class EditProfileScreen extends StatefulWidget {
  final User user; // Receives the current user's data

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;

  late String _selectedPosition;
  late String _selectedGender;
  bool _isLoading = false;

  final List<String> _positions = [
    'Point Guard',
    'Shooting Guard',
    'Small Forward',
    'Power Forward',
    'Center'
  ];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    // Pre-populate the form fields with the user's current data
    _nameController = TextEditingController(text: widget.user.name);
    _ageController =
        TextEditingController(text: widget.user.age?.toString() ?? '');
    _selectedGender = widget.user.gender ?? 'Male';

    // Player-specific fields
    if (widget.user.role == 'Player') {
      _weightController =
          TextEditingController(text: widget.user.weight?.toString() ?? '');
      _heightController =
          TextEditingController(text: widget.user.height?.toString() ?? '');
      _selectedPosition = widget.user.position ?? 'Point Guard';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    if (widget.user.role == 'Player') {
      _weightController.dispose();
      _heightController.dispose();
    }
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final firebaseService =
        Provider.of<FirebaseService>(context, listen: false);

    // Create a map of the data to be updated
    final Map<String, dynamic> updatedData = {
      'name': _nameController.text.trim(),
      'age': int.tryParse(_ageController.text),
      'gender': _selectedGender,
    };

    // Add player-specific data if the user is a Player
    if (widget.user.role == 'Player') {
      updatedData.addAll({
        'weight': double.tryParse(_weightController.text),
        'height': double.tryParse(_heightController.text),
        'position': _selectedPosition,
      });
    }

    try {
      // Use our existing service method to update the profile
      await firebaseService.updateUserProfile(widget.user.userId, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green),
        );
        // Go back to the previous screen (SettingsScreen)
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to update profile: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // --- Common Fields for Both Roles ---
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: 'Full Name'),
                  validator: (value) =>
                      value!.trim().isEmpty ? 'Please enter your name' : null,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(labelText: 'Gender'),
                  items: _genders
                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedGender = value!),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText: 'Age'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'Please enter your age';
                    if (int.tryParse(value) == null)
                      return 'Please enter a valid number';
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // --- Player-Specific Fields ---
                if (widget.user.role == 'Player') ...[
                  TextFormField(
                    controller: _heightController,
                    decoration: InputDecoration(labelText: 'Height (cm)'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _weightController,
                    decoration: InputDecoration(labelText: 'Weight (kg)'),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedPosition,
                    decoration: InputDecoration(labelText: 'Position'),
                    items: _positions
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedPosition = value!),
                  ),
                ],

                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Save Changes',
                          style: TextStyle(color: Colors.white),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
