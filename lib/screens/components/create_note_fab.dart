import 'package:flutter/material.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/screens/components/shared_fab.dart';
import 'package:happy_notes/screens/new_note/new_note.dart';
import 'package:happy_notes/utils/util.dart';

/// Floating Action Button for creating notes.
class CreateNoteFAB extends StatelessWidget {
  final bool isPrivate;
  final String heroTag;
  final String successMessage;
  final VoidCallback? onPressed;

  const CreateNoteFAB({
    super.key,
    required this.isPrivate,
    required this.heroTag,
    this.successMessage = 'Note saved successfully.',
    this.onPressed,
  });

  Future<void> _handleCreateNote(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // NewNote pops with Note on successful save, and null on cancel/back.
    final Note? savedNote = await Navigator.push<Note>(
      context,
      MaterialPageRoute(
        builder: (context) => NewNote(isPrivate: isPrivate),
      ),
    );
    if (savedNote != null) {
      Util.showInfo(scaffoldMessenger, successMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.85,
      child: SharedFab(
        icon: Icons.edit_outlined,
        isPrivate: isPrivate,
        busy: false,
        mini: false,
        onPressed: onPressed ?? () => _handleCreateNote(context),
        heroTag: heroTag,
      ),
    );
  }
}
