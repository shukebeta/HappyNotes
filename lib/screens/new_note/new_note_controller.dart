import 'package:happy_notes/services/dialog_services.dart';
import 'package:flutter/material.dart';
import '../../models/note_model.dart';
import '../../providers/notes_provider.dart';
import '../../utils/util.dart';
import 'package:provider/provider.dart';

class NewNoteController {
  NewNoteController();

  // Returns true if saved successfully (when used modally), false otherwise.
  // Calls onSaveSuccessInMainMenu if provided (when used in MainMenu).
  Future<bool> saveNote(BuildContext context, {VoidCallback? onSaveSuccessInMainMenu}) async {
    final scaffoldMessengerSate = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context); // Get navigator
    final noteModel = context.read<NoteModel>();
    final notesProvider = context.read<NotesProvider>();

    if (noteModel.content.trim() == '') {
      Util.showInfo(scaffoldMessengerSate, 'Please write something');
      return false; // Indicate failure
    }
    try {
      // Use NotesProvider.addNote instead of direct service call
      final savedNote = await notesProvider.addNote(
        noteModel.content,
        isPrivate: noteModel.isPrivate,
        isMarkdown: noteModel.isMarkdown,
        publishDateTime: noteModel.publishDateTime,
      );

      if (savedNote != null) {
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
      } else {
        // Handle case where addNote returned null (failed)
        Util.showError(scaffoldMessengerSate, notesProvider.addError ?? 'Failed to save note');
        return false; // Indicate failure
      }
    } catch (e) {
      Util.showError(scaffoldMessengerSate, 'Failed to save note: $e');
      return false;
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
