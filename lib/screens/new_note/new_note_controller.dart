import 'package:happy_notes/services/dialog_services.dart';
import 'package:flutter/material.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../providers/notes_provider.dart';
import '../../utils/util.dart';
import 'package:provider/provider.dart';

class NewNoteController {
  NewNoteController();

  // Returns created Note if saved successfully (when used modally), null otherwise.
  // Calls onSaveSuccessInMainMenu if provided (when used in MainMenu).
  Future<Note?> saveNote(BuildContext context, {VoidCallback? onSaveSuccessInMainMenu}) async {
    final scaffoldMessengerSate = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context); // Get navigator
    final noteModel = context.read<NoteModel>();
    final notesProvider = context.read<NotesProvider>();

    if (noteModel.content.trim() == '') {
      Util.showInfo(scaffoldMessengerSate, 'Please write something');
      return null; // Indicate failure
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
          // Otherwise (modal context), pop with saved note for caller to use
          navigator.pop(savedNote);
        }
        return savedNote; // Return the created note
      } else {
        // Handle case where addNote returned null (failed)
        final errorMessage = notesProvider.addError ?? 'Failed to save note';
        Util.showError(scaffoldMessengerSate, errorMessage);
        return null; // Indicate failure
      }
    } catch (e) {
      Util.showError(scaffoldMessengerSate, 'Failed to save note: $e');
      return null;
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
