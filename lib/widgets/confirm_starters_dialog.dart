// lib/widgets/confirm_starters_dialog.dart

import 'package:flutter/material.dart';
import '../models/user.dart';

class ConfirmStartersDialog extends StatefulWidget {
  final List<User> participants;

  const ConfirmStartersDialog({Key? key, required this.participants})
      : super(key: key);

  @override
  _ConfirmStartersDialogState createState() => _ConfirmStartersDialogState();
}

class _ConfirmStartersDialogState extends State<ConfirmStartersDialog> {
  // Use a Set for efficient add/remove operations
  final Set<String> _selectedPlayerIds = {};

  @override
  void initState() {
    super.initState();
    // Pre-select the first 5 players by default
    widget.participants.take(5).forEach((player) {
      _selectedPlayerIds.add(player.userId);
    });
  }

  void _onSelectionChanged(String playerId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedPlayerIds.add(playerId);
      } else {
        _selectedPlayerIds.remove(playerId);
      }
    });
  }

  void _onConfirm() {
    if (_selectedPlayerIds.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select exactly 5 starting players.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Return the confirmed set of starter IDs
    Navigator.of(context).pop(_selectedPlayerIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm Starting Lineup'),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.participants.length,
          itemBuilder: (context, index) {
            final player = widget.participants[index];
            return CheckboxListTile(
              title: Text(player.name ?? 'Unknown Player'),
              value: _selectedPlayerIds.contains(player.userId),
              onChanged: (isSelected) =>
                  _onSelectionChanged(player.userId, isSelected!),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(), // Return null on cancel
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _onConfirm,
          child: Text('Confirm (${_selectedPlayerIds.length}/5)'),
        ),
      ],
    );
  }
}
