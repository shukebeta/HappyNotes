import 'package:flutter/material.dart';
import '../entities/note.dart';
import '../services/notes_services.dart';
import '../utils/util.dart';

class NoteDetailController {
  final NotesService _notesService;
  final TextEditingController noteController = TextEditingController();
  final FocusNode noteFocusNode = FocusNode();

  NoteDetailController({required NotesService notesService})
      : _notesService = notesService;

  bool isPrivate = false;
  bool isEditing = false;

  Future<Note> fetchNote(int noteId) async {
    final note = await _notesService.get(noteId);
    noteController.text = note.content;
    isPrivate = note.isPrivate;
    return note;
  }

  Future<void> saveNote(
      BuildContext context, int noteId, void Function() onSuccess) async {
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

  Future<void> deleteNote(BuildContext context, int noteId,
      void Function() onSuccess) async {
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

  void dispose() {
    noteController.dispose();
    noteFocusNode.dispose();
  }
}
