import 'package:happy_notes/app_config.dart';
import '../../entities/note.dart';
import '../../services/notes_services.dart';
import '../../utils/util.dart';
import 'package:flutter/material.dart';

class DiscoveryController {
  final NotesService _notesService;
  List<Note> notes = [];
  int _totalNotes = 1;
  bool isLoading = false;

  DiscoveryController({required NotesService notesService}): _notesService = notesService;

  int get totalPages => (_totalNotes / AppConfig.pageSize).ceil();

  Future<void> loadNotes(BuildContext context, int pageNumber) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      isLoading = true;
      var result = await _notesService.latest(AppConfig.pageSize, pageNumber);
      _totalNotes = result.totalNotes;
      notes = result.notes;
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteNote(BuildContext context, int noteId) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      await _notesService.delete(noteId);
      if (!context.mounted) return;
      await loadNotes(context, 1); // Reload notes after deletion
      Util.showInfo(scaffoldContext, 'Note successfully deleted.');
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    }
  }
}
