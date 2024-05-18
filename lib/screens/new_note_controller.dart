import 'package:HappyNotes/services/dialog_services.dart';
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
              (await DialogService.showUnsavedChangesDialog(context) ??
                  false))) {
        navigator.pop();
      }
    }
  }
}
