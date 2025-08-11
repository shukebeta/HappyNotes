import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/services/note_tag_service.dart';
import 'package:happy_notes/providers/note_list_provider.dart';
import 'package:happy_notes/utils/operation_result.dart';

class TagNotesProvider extends NoteListProvider {
  final NotesService _notesService;
  final NoteTagService _noteTagService;

  TagNotesProvider(this._notesService, this._noteTagService);

  // Tag cloud state
  Map<String, int> _tagCloud = {};
  Map<String, int> get tagCloud => _tagCloud;

  bool _isLoadingTagCloud = false;
  bool get isLoadingTagCloud => _isLoadingTagCloud;

  String? _tagCloudError;
  String? get tagCloudError => _tagCloudError;

  // Tag-specific state
  String _currentTag = '';
  String get currentTag => _currentTag;
  
  // Alias for compatibility
  List<Note> get tagNotes => notes;

  @override
  void clearAllData() {
    _tagCloud.clear();
    _isLoadingTagCloud = false;
    _tagCloudError = null;
    _currentTag = '';
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
    await navigateToPage(pageNumber);
  }

  /// Clear tag notes data
  void clearTagNotes() {
    _currentTag = '';
    clearAllData();
  }

  @override
  Future<OperationResult<void>> deleteNote(int noteId) async {
    // Store original tag cloud for rollback
    final originalTagCloud = Map<String, int>.from(_tagCloud);
    
    // Update tag cloud optimistically
    if (_currentTag.isNotEmpty && _tagCloud.containsKey(_currentTag)) {
      final currentCount = _tagCloud[_currentTag] ?? 0;
      if (currentCount > 1) {
        _tagCloud[_currentTag] = currentCount - 1;
      } else {
        _tagCloud.remove(_currentTag);
      }
    }
    
    // Call parent delete method
    final result = await super.deleteNote(noteId);
    
    // If delete failed, rollback tag cloud changes
    if (result.isError) {
      _tagCloud = originalTagCloud;
      notifyListeners();
    }
    
    return result;
  }

  /// Refresh current tag notes
  Future<void> refreshTagNotes() async {
    if (_currentTag.isNotEmpty) {
      await refresh();
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
  Future<NotesResult> fetchNotes(int pageSize, int pageNumber) async {
    if (_currentTag.isEmpty) {
      // Return empty result if no tag selected
      return NotesResult([], 0);
    }
    return await _notesService.tagNotes(_currentTag, pageSize, pageNumber);
  }

  @override
  Future<void> performDelete(int noteId) async {
    await _notesService.delete(noteId);
  }

}