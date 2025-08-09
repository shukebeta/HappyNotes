import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/services/note_tag_service.dart';
import 'package:happy_notes/providers/provider_base.dart';

class TagProvider extends AuthAwareProvider {
  final NotesService _notesService;
  final NoteTagService _noteTagService;

  TagProvider(this._notesService, this._noteTagService) {
    try {
      _pageSize = AppConfig.pageSize;
    } catch (e) {
      _pageSize = 10; // Default for tests
    }
  }

  // Tag cloud state
  Map<String, int> _tagCloud = {};
  Map<String, int> get tagCloud => _tagCloud;

  bool _isLoadingTagCloud = false;
  bool get isLoadingTagCloud => _isLoadingTagCloud;

  String? _tagCloudError;
  String? get tagCloudError => _tagCloudError;

  // Tag notes state
  String _currentTag = '';
  String get currentTag => _currentTag;

  List<Note> _tagNotes = [];
  List<Note> get tagNotes => _tagNotes;

  int _totalNotes = 0;
  int _currentPage = 1;
  late final int _pageSize;

  bool _isLoadingNotes = false;
  bool get isLoadingNotes => _isLoadingNotes;

  String? _notesError;
  String? get notesError => _notesError;

  // Computed properties
  int get totalTagNotes => _totalNotes <= 0 ? 1 : _totalNotes;
  int get totalPages => (totalTagNotes / _pageSize).ceil();
  int get currentPage => _currentPage;

  @override
  void clearAllData() {
    _tagCloud.clear();
    _isLoadingTagCloud = false;
    _tagCloudError = null;
    _currentTag = '';
    _tagNotes.clear();
    _totalNotes = 0;
    _currentPage = 1;
    _isLoadingNotes = false;
    _notesError = null;
    notifyListeners();
  }

  /// Load tag cloud data with caching
  Future<void> loadTagCloud({bool forceRefresh = false}) async {
    if (!forceRefresh && _tagCloud.isNotEmpty && _tagCloudError == null) {
      return; // Use cached data
    }

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

  /// Load notes for a specific tag with pagination
  Future<void> loadTagNotes(String tag, int pageNumber) async {
    if (tag.trim().isEmpty) {
      clearTagNotes();
      return;
    }

    _currentTag = tag;
    _currentPage = pageNumber;

    final result = await executeWithErrorHandling<NotesResult>(
      operation: () => _notesService.tagNotes(tag, _pageSize, pageNumber),
      setLoading: (loading) => _isLoadingNotes = loading,
      setError: (error) => _notesError = error,
      operationName: 'load tag notes',
    );

    if (result != null) {
      _tagNotes = result.notes;
      _totalNotes = result.totalNotes;
      _notesError = null;
      notifyListeners();
    }
  }

  /// Clear tag notes data
  void clearTagNotes() {
    _currentTag = '';
    _tagNotes.clear();
    _totalNotes = 0;
    _currentPage = 1;
    _notesError = null;
    notifyListeners();
  }

  /// Delete a note from tag notes
  Future<bool> deleteNote(int noteId) async {
    _isLoadingNotes = true;
    _notesError = null;
    notifyListeners();

    try {
      await _notesService.delete(noteId);
      
      // Remove note from local results and update count
      _tagNotes.removeWhere((note) => note.id == noteId);
      if (_totalNotes > 0) _totalNotes--;
      
      // Also update tag cloud count if the deleted note affects current tag
      if (_currentTag.isNotEmpty && _tagCloud.containsKey(_currentTag)) {
        final currentCount = _tagCloud[_currentTag] ?? 0;
        if (currentCount > 1) {
          _tagCloud[_currentTag] = currentCount - 1;
        } else {
          _tagCloud.remove(_currentTag);
        }
      }
      
      _notesError = null;
      return true;
    } catch (e) {
      _notesError = handleServiceError(e, 'delete note');
      return false;
    } finally {
      _isLoadingNotes = false;
      notifyListeners();
    }
  }

  /// Refresh current tag notes
  Future<void> refreshTagNotes() async {
    if (_currentTag.isNotEmpty) {
      await loadTagNotes(_currentTag, _currentPage);
    }
  }

  /// Get tag count for a specific tag
  int getTagCount(String tag) {
    return _tagCloud[tag] ?? 0;
  }

  /// Check if a tag exists in the cloud
  bool hasTag(String tag) {
    return _tagCloud.containsKey(tag);
  }

  /// Get all available tags
  List<String> get allTags {
    return _tagCloud.keys.toList()..sort();
  }

  /// Get top N tags by count
  List<MapEntry<String, int>> getTopTags(int limit) {
    final sortedEntries = _tagCloud.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(limit).toList();
  }

  @override
  Future<void> onLogin() async {
    // Load tag cloud on login for immediate availability
    await loadTagCloud();
  }
}