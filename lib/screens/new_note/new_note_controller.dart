import 'package:happy_notes/screens/account/user_session.dart';
import 'package:happy_notes/services/dialog_services.dart';
import 'package:flutter/material.dart';
import 'package:happy_notes/typedefs.dart';
import '../../entities/note.dart';
import '../../services/notes_services.dart';
import '../../utils/util.dart';

class NewNoteController {
  final NotesService _notesService;

  NewNoteController({required NotesService notesService}) : _notesService = notesService;
  final TextEditingController noteController = TextEditingController();
  final FocusNode noteFocusNode = FocusNode();

  bool get nothingToSave => noteController.text.trim().isEmpty;

  Future<void> saveNote(BuildContext context, bool isPrivate, bool isMarkdown, SaveNoteCallback? onNoteSaved) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    if (nothingToSave) {
      Util.showInfo(scaffoldContext, 'Please write something');
      return;
    }
    try {
      var navigator = Navigator.of(context);
      var content = noteController.text;
      var isLong = content.length < 1024;
      final noteId = await _notesService.post(noteController.text, isPrivate, isMarkdown);
      if (onNoteSaved != null) {
        final note = Note(
            id: noteId,
            userId: UserSession().id!,
            content: content,
            isLong: isLong,
            isPrivate: isPrivate,
            isMarkdown: isMarkdown,
            createAt: (DateTime.now().millisecondsSinceEpoch / 1000).round());
        noteController.text = '';
        noteFocusNode.unfocus();
        onNoteSaved(note);
      }
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    }
  }

  onPopHandler(BuildContext context, bool didPop) async {
    if (!didPop) {
      final navigator = Navigator.of(context);
      if (noteController.text.isEmpty ||
          (noteController.text.isNotEmpty && (await DialogService.showUnsavedChangesDialog(context) ?? false))) {
        navigator.pop();
      }
    }
  }

  void dispose() {
    noteController.dispose();
    noteFocusNode.dispose();
  }
}
