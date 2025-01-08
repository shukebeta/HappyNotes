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
      final noteId = await _notesService.post(noteModel);
      var content = noteModel.content;
      noteModel.content = '';
      noteModel.unfocus();
      if (onNoteSaved != null) {
        final note = Note(
            id: noteId,
            userId: UserSession().id!,
            content: content,
            isLong: content.length < 1024,
            isPrivate: noteModel.isPrivate,
            isMarkdown: noteModel.isMarkdown,
            createdAt: _getCreatedAt(noteModel.publishDateTime));
        onNoteSaved(note);
      }
    } catch (error) {
      Util.showError(scaffoldMessengerSate, error.toString());
    }
  }

  int _getCreatedAt(String publishDate) {
    var now = DateTime.now();
    // If the publishDate is empty, use DateTime.now()
    final sourceDateTime = publishDate.isEmpty
        ? now
        : DateTime.parse(publishDate).add(
      Duration(
        hours: now.hour,
        minutes: now.minute,
        seconds: now.second,
      ),
    );

    // Return the Unix timestamp
    return sourceDateTime.toUtc().millisecondsSinceEpoch ~/ 1000;
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
