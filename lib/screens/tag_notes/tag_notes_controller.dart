import 'package:happy_notes/app_config.dart';
import '../../entities/note.dart';
import '../../services/notes_services.dart';
import '../../utils/util.dart';
import 'package:flutter/material.dart';

class TagNotesController {
  final NotesService _notesService;
  List<Note> notes = [];
  int _realTotalNotes = 1;
  int get _totalNotes => _realTotalNotes <= 0 ? 1 : _realTotalNotes;
  bool isLoading = false;

  TagNotesController({required NotesService notesService}): _notesService = notesService;

  int get totalPages => (_totalNotes / AppConfig.pageSize).ceil();

  Future<void> loadNotes(BuildContext context, String tag, int pageNumber, bool myNotesOnly) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      isLoading = true;
      var result = await _notesService.tagNotes(tag, AppConfig.pageSize, pageNumber, myNotesOnly);
      _realTotalNotes = result.totalNotes;
      notes = result.notes;
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    } finally {
      isLoading = false;
    }
  }
}
