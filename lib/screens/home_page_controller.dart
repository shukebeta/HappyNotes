import '../entities/note.dart';
import '../services/notes_services.dart';
import '../utils/util.dart';
import 'package:flutter/material.dart';

class HomePageController {
  final NotesService _notesService;
  List<Note> notes = [];
  int _pageSize = 5;
  int currentPageNumber = 1;
  int totalNotes = 1;
  bool isLoading = false;

  HomePageController(this._notesService);

  int get totalPages => (totalNotes / _pageSize).ceil();
  bool get isFirstPage => currentPageNumber == 1;

  Future<void> loadNotes(BuildContext context, int pageNumber) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      isLoading = true;
      var result = await _notesService.myLatest(_pageSize, pageNumber);
      totalNotes = result.totalNotes;
      notes = result.notes;
      currentPageNumber = pageNumber;
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    } finally {
      isLoading = false;
    }
  }
}
