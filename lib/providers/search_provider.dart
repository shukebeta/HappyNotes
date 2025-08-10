import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/services/note_tag_service.dart';
import 'package:happy_notes/providers/note_list_provider.dart';
import 'package:happy_notes/utils/operation_result.dart';

class SearchProvider extends NoteListProvider {
  final NotesService _notesService;
  final NoteTagService _noteTagService;

  SearchProvider(this._notesService, this._noteTagService);

  // Search-specific state
  String _currentQuery = '';
  String get currentQuery => _currentQuery;
  
  // Alias for compatibility
  List<Note> get searchResults => notes;

  // Tag cloud state
  Map<String, int> _tagCloud = {};
  Map<String, int> get tagCloud => _tagCloud;

  bool _isLoadingTagCloud = false;
  bool get isLoadingTagCloud => _isLoadingTagCloud;

  String? _tagCloudError;
  String? get tagCloudError => _tagCloudError;


  @override
  void clearAllData() {
    _currentQuery = '';
    _tagCloud.clear();
    _isLoadingTagCloud = false;
    _tagCloudError = null;
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

  /// Load tag cloud data
  Future<void> loadTagCloud() async {
    final result = await executeWithErrorHandling<List<dynamic>>(
      operation: () => _noteTagService.getMyTagCloud(),
      setLoading: (loading) => _isLoadingTagCloud = loading,
      setError: (error) => _tagCloudError = error,
      operationName: 'load tag cloud',
    );

    if (result != null) {
      _tagCloud = {for (var item in result) item.tag: item.count};
      _tagCloudError = null;
      notifyListeners();
    }
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

  @override
  Future<void> onLogin() async {
    // Load tag cloud on login for immediate availability
    await loadTagCloud();
  }
}