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

  NewNoteController({required NotesService notesService}) : _notesService = notesService;

  Future<void> saveNote(BuildContext context, SaveNoteCallback? onNoteSaved) async {
    final scaffoldMessengerSate = ScaffoldMessenger.of(context);
    final noteModel = context.read<NoteModel>();
    if (noteModel.content.trim() == '') {
      Util.showInfo(scaffoldMessengerSate, 'Please write something');
      return;
    }
    try {
      var content = noteModel.content;
      var isLong = content.length < 1024;
      final noteId = await _notesService.post(content, noteModel.isPrivate, noteModel.isMarkdown);
      noteModel.content = '';
      noteModel.unfocus();
      if (onNoteSaved != null) {
        final note = Note(
            id: noteId,
            userId: UserSession().id!,
            content: content,
            isLong: isLong,
            isPrivate: noteModel.isPrivate,
            isMarkdown: noteModel.isMarkdown,
            createdAt: (DateTime.now().millisecondsSinceEpoch / 1000).round());
        onNoteSaved(note);
      }
    } catch (error) {
      Util.showError(scaffoldMessengerSate, error.toString());
    }
  }

  onPopHandler(BuildContext context, bool didPop) async {
    if (!didPop) {
      final noteModel = context.read<NoteModel>();
      final navigator = Navigator.of(context);
      var focusScopeNode = FocusScope.of(context);
      if (noteModel.content.isEmpty ||
          (noteModel.content.isNotEmpty && (await DialogService.showUnsavedChangesDialog(context) ?? false))) {
        focusScopeNode.unfocus();
        navigator.pop();
      }
    }
  }
}
