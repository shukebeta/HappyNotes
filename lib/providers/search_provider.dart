import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/providers/note_list_provider.dart';
import 'package:happy_notes/utils/operation_result.dart';

class SearchProvider extends NoteListProvider {
  final NotesService _notesService;

  SearchProvider(this._notesService);

  @override
  NotesService get notesService => _notesService;

  // Search-specific state
  String _currentQuery = '';
  String get currentQuery => _currentQuery;

  // Alias for compatibility
  List<Note> get searchResults => notes;


  @override
  void clearAllData() {
    _currentQuery = '';
    super.clearAllData();
  }

  /// Search for notes with pagination
  Future<void> searchNotes(String query, int pageNumber) async {
    if (query.trim().isEmpty) {
      clearSearchResults();
      return;
    }

    _currentQuery = query;
    await navigateToPage(pageNumber);
  }

  /// Clear search results
  void clearSearchResults() {
    _currentQuery = '';
    clearAllData();
  }


  @override
  Future<OperationResult<void>> deleteNote(int noteId) async {
    return await super.deleteNote(noteId);
  }

  /// Refresh current search
  Future<void> refreshSearch() async {
    if (_currentQuery.isNotEmpty) {
      await refresh();
    }
  }

  @override
  Future<NotesResult> fetchNotes(int pageSize, int pageNumber) async {
    if (_currentQuery.isEmpty) {
      // Return empty result if no query
      return NotesResult([], 0);
    }
    return await _notesService.searchNotes(_currentQuery, pageSize, pageNumber);
  }

  @override
  Future<void> performDelete(int noteId) async {
    await _notesService.delete(noteId);
  }

}