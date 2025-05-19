import 'package:flutter/material.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../services/dialog_services.dart';
import '../../services/notes_services.dart';
import '../../utils/util.dart';
import 'package:provider/provider.dart';

class NoteDetailController {
  final NotesService _notesService;
  late Note _originalNote;

  NoteDetailController({required NotesService notesService}) : _notesService = notesService;

  bool isPrivate = false;
  bool isEditing = false;
  bool isLoading = false;

  Future<Note?> fetchNote(BuildContext context, int noteId, {bool includeDeleted = false}) async {
    isLoading = true;
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      _originalNote = await _notesService.get(noteId, includeDeleted: includeDeleted);
      return _originalNote;
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
      return null;
    } finally {
      isLoading = false;
    }
  }

  Future<void> saveNote(BuildContext context, int noteId, void Function() onSuccess) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    var noteModel = context.read<NoteModel>();
    try {
      await _notesService.update(noteId, noteModel.content, noteModel.isPrivate, noteModel.isMarkdown);
      isEditing = false;
      onSuccess();
      Util.showInfo(scaffoldContext, 'Note successfully updated.');
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    }
  }

  Future<void> deleteNote(BuildContext context, int noteId, void Function(bool needRefresh) onSuccess) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      await _notesService.delete(noteId);
      onSuccess(true);
      Util.showInfo(scaffoldContext, 'Note successfully deleted.');
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
      onSuccess(false);
    }
  }

  Future<void> undeleteNote(BuildContext context, int noteId, void Function(bool needRefresh) onSuccess) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      await _notesService.undelete(noteId);
      onSuccess(true);
      Util.showInfo(scaffoldContext, 'Note successfully undeleted.');
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
      onSuccess(false);
    }
  }

  onPopHandler(BuildContext context, bool didPop) async {
    if (!didPop) {
      final noteModel = context.read<NoteModel>();
      final navigator = Navigator.of(context);
      if (!isEditing || (noteModel.content == _originalNote.content) || (await DialogService.showUnsavedChangesDialog(context) ?? false)) {
        navigator.pop(false);
      }
    }
  }
}
