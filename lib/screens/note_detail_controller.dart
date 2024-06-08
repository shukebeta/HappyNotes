import 'package:flutter/material.dart';
import '../entities/note.dart';
import '../services/dialog_services.dart';
import '../services/notes_services.dart';
import '../utils/util.dart';

class NoteDetailController {
  final NotesService _notesService;
  final TextEditingController noteController = TextEditingController();
  final FocusNode noteFocusNode = FocusNode();
  late Note _originalNote;

  NoteDetailController({required NotesService notesService})
      : _notesService = notesService;

  bool isPrivate = false;
  bool isEditing = false;

  Future<Note> fetchNote(int noteId) async {
    _originalNote = await _notesService.get(noteId);
    noteController.text = isEditing? _originalNote.content : _originalNote.formattedContent;
    isPrivate = _originalNote.isPrivate;
    return _originalNote;
  }

  Future<void> saveNote(BuildContext context, int noteId, void Function() onSuccess) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      await _notesService.update(noteId, noteController.text, isPrivate);
      isEditing = false;
      onSuccess();
      Util.showInfo(scaffoldContext, 'Note successfully updated.');
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    }
  }

  Future<void> deleteNote(BuildContext context, int noteId, void Function() onSuccess) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await _notesService.delete(noteId);
      navigator.pop();
      Util.showInfo(scaffoldContext, 'Note successfully deleted.');
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    }
  }

  onPopHandler(BuildContext context, bool didPop) async {
    if (!didPop) {
      final navigator = Navigator.of(context);
      if (!isEditing || noteController.text == _originalNote.content ||
          (await DialogService.showUnsavedChangesDialog(context) ?? false)
      ) {
        navigator.pop();
      }
    }
  }

  void dispose() {
    noteController.dispose();
    noteFocusNode.dispose();
  }
}
