import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/notes_services.dart';
import '../utils/util.dart';

class NewNoteController {
  final NotesService _notesService;
  NewNoteController({required NotesService notesService}): _notesService = notesService;
  final TextEditingController noteController = TextEditingController();

  Future<void> saveNote(BuildContext context, bool isPrivate) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final noteId = await NotesService.post(noteController.text, isPrivate);
      navigator.pop({'noteId': noteId});
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    }
  }

  onPopHandler(BuildContext context, bool didPop) async {
    if (!didPop) {
      final navigator = Navigator.of(context);
      if (noteController.text.isEmpty ||
          (noteController.text.isNotEmpty &&
              (await NewNoteController.showUnsavedChangesDialog(context) ??
                  false))) {
        navigator.pop();
      }
    }
  }

  static Future<bool?> showUnsavedChangesDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text(
            'You have unsaved changes. Do you really want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }
}
