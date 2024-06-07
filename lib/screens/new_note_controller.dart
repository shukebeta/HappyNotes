import 'package:happy_notes/services/dialog_services.dart';
import 'package:flutter/material.dart';
import 'package:happy_notes/typedefs.dart';

import '../services/notes_services.dart';
import '../utils/util.dart';
import 'main_menu.dart';

class NewNoteController {
  final NotesService _notesService;
  NewNoteController({required NotesService notesService}): _notesService = notesService;
  final TextEditingController noteController = TextEditingController();
  final FocusNode noteFocusNode = FocusNode();
  bool get nothingToSave => noteController.text.trim().isEmpty;

  Future<void> saveNote(BuildContext context, bool isPrivate, SaveNoteCallback? onNoteSaved) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    if (nothingToSave) {
      Util.showInfo(scaffoldContext, 'Please write something');
      return;
    }
    try {
      var navigator = Navigator.of(context);;
      final noteId = await _notesService.post(noteController.text, isPrivate);
      if (onNoteSaved != null) {
        noteController.text = '';
        noteFocusNode.unfocus();
        onNoteSaved(noteId);
      }
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

  void dispose() {
    noteController.dispose();
    noteFocusNode.dispose();
  }
}

