import '../entities/note.dart';
import '../services/notes_services.dart';
import '../utils/util.dart';
import 'package:flutter/material.dart';

class MemoriesController {
  final NotesService _notesService;
  List<Note> notes = [];
  bool isLoading = false;

  MemoriesController(this._notesService);

  Future<void> loadNotes(BuildContext context) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      isLoading = true;
      var result = await _notesService.memories();
      notes = result.notes;
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    } finally {
      isLoading = false;
    }
  }
}
