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
  final TextEditingController noteController = TextEditingController();
  final FocusNode noteFocusNode = FocusNode();

  Future<void> saveNote(BuildContext context, SaveNoteCallback? onNoteSaved) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    final noteModel = context.read<NoteModel>();
    if (noteModel.content.trim() == '') {
      Util.showInfo(scaffoldContext, 'Please write something');
      return;
    }
    try {
      var navigator = Navigator.of(context);
      var content = noteModel.content;
      var isLong = content.length < 1024;
      final noteId = await _notesService.post(content, noteModel.isPrivate, noteModel.isMarkdown);
      if (onNoteSaved != null) {
        final note = Note(
            id: noteId,
            userId: UserSession().id!,
            content: content,
            isLong: isLong,
            isPrivate: noteModel.isPrivate,
            isMarkdown: noteModel.isMarkdown,
            createAt: (DateTime.now().millisecondsSinceEpoch / 1000).round());
        onNoteSaved(note);
      }
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    }
  }

  onPopHandler(BuildContext context, bool didPop) async {
    if (!didPop) {
      final noteModel = context.read<NoteModel>();
      final navigator = Navigator.of(context);
      if (noteModel.content.isEmpty ||
          (noteModel.content.isNotEmpty && (await DialogService.showUnsavedChangesDialog(context) ?? false))) {
        navigator.pop();
      }
    }
  }
}