import 'package:happy_notes/screens/account/user_session.dart';
import 'package:happy_notes/services/dialog_services.dart';
import 'package:flutter/material.dart';
import 'package:happy_notes/typedefs.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../services/notes_services.dart';
import '../../utils/util.dart';
import 'package:provider/provider.dart';

class NewNoteController {
  final NotesService _notesService;

  NewNoteController({required NotesService notesService})
      : _notesService = notesService;

  // Returns true if saved successfully (when used modally), false otherwise.
  // Calls onSaveSuccessInMainMenu if provided (when used in MainMenu).
  Future<bool> saveNote(BuildContext context, {VoidCallback? onSaveSuccessInMainMenu}) async {
    final scaffoldMessengerSate = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context); // Get navigator
    final noteModel = context.read<NoteModel>();
    if (noteModel.content.trim() == '') {
      Util.showInfo(scaffoldMessengerSate, 'Please write something');
      return false; // Indicate failure
    }
    try {
      await _notesService.post(noteModel);
      noteModel.initialContent = '';
      noteModel.content = '';
      noteModel.unfocus();

      if (onSaveSuccessInMainMenu != null) {
        // If callback provided (MainMenu context), call it instead of popping
        onSaveSuccessInMainMenu();
      } else {
        // Otherwise (modal context), pop with true on success
        navigator.pop(true);
      }
      return true; // Indicate success regardless of context
    } catch (error) {
      Util.showError(scaffoldMessengerSate, error.toString());
      return false; // Indicate failure
    }
  }

  onPopHandler(BuildContext context, bool didPop) async {
    if (!didPop) {
      final noteModel = context.read<NoteModel>();
      final navigator = Navigator.of(context);
      var focusScopeNode = FocusScope.of(context);
      if (noteModel.content.isEmpty ||
          noteModel.content.trim() == '#${noteModel.initialContent}' ||
          (await DialogService.showUnsavedChangesDialog(context) ?? false)) {
        noteModel.initialContent = '';
        focusScopeNode.unfocus();
        navigator.pop();
      }
    }
  }
}
