import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/services/note_tag_service.dart';
import 'package:happy_notes/providers/provider_base.dart';

class SearchProvider extends AuthAwareProvider {
  final NotesService _notesService;
  final NoteTagService _noteTagService;

  SearchProvider(this._notesService, this._noteTagService) {
    try {
      _pageSize = AppConfig.pageSize;
    } catch (e) {
      _pageSize = 10; // Default for tests
    }
  }

  // Search state
  List<Note> _searchResults = [];
  List<Note> get searchResults => _searchResults;

  int _totalCount = 0;
  int _currentPage = 1;
  String _currentQuery = '';
  late final int _pageSize;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Tag cloud state
  Map<String, int> _tagCloud = {};
  Map<String, int> get tagCloud => _tagCloud;

  bool _isLoadingTagCloud = false;
  bool get isLoadingTagCloud => _isLoadingTagCloud;

  String? _tagCloudError;
  String? get tagCloudError => _tagCloudError;

  // Computed properties
  int get totalNotes => _totalCount <= 0 ? 1 : _totalCount;
  int get totalPages => (totalNotes / _pageSize).ceil();
  int get currentPage => _currentPage;
  String get currentQuery => _currentQuery;

  @override
  void clearAllData() {
    _searchResults.clear();
    _totalCount = 0;
    _currentPage = 1;
    _currentQuery = '';
    _isLoading = false;
    _error = null;
    _tagCloud.clear();
    _isLoadingTagCloud = false;
    _tagCloudError = null;
    notifyListeners();
  }

  /// Search for notes with pagination
  Future<void> searchNotes(String query, int pageNumber) async {
    if (query.trim().isEmpty) {
      clearSearchResults();
      return;
    }

    _currentQuery = query;
    _currentPage = pageNumber;

    final result = await executeWithErrorHandling<NotesResult>(
      operation: () => _notesService.searchNotes(query, _pageSize, pageNumber),
      setLoading: (loading) => _isLoading = loading,
      setError: (error) => _error = error,
      operationName: 'search notes',
    );

    if (result != null) {
      _searchResults = result.notes;
      _totalCount = result.totalNotes;
      _error = null;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearchResults() {
    _searchResults.clear();
    _totalCount = 0;
    _currentPage = 1;
    _currentQuery = '';
    _error = null;
    notifyListeners();
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

  /// Delete a note from search results
  Future<bool> deleteNote(int noteId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _notesService.delete(noteId);
      
      // Remove note from local results and update count
      _searchResults.removeWhere((note) => note.id == noteId);
      if (_totalCount > 0) _totalCount--;
      
      _error = null;
      return true;
    } catch (e) {
      _error = handleServiceError(e, 'delete note');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh current search
  Future<void> refreshSearch() async {
    if (_currentQuery.isNotEmpty) {
      await searchNotes(_currentQuery, _currentPage);
    }
    // Explicitly return completed future for empty query case
  }

  @override
  Future<void> onLogin() async {
    // Load tag cloud on login for immediate availability
    await loadTagCloud();
  }
}