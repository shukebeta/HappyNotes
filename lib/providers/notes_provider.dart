import 'package:flutter/foundation.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/note_model.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/providers/provider_base.dart';
import 'package:happy_notes/exceptions/api_exception.dart';

class NotesProvider extends AuthAwareProvider {
  final NotesService _notesService;

  NotesProvider(this._notesService) {
    try {
      _pageSize = AppConfig.pageSize;
    } catch (e) {
      _pageSize = 10; // Default for tests
    }
  }

  // Page-based state management
  int _currentPage = 1;
  int get currentPage => _currentPage;

  List<Note> _currentPageNotes = [];
  List<Note> get notes => _currentPageNotes; // For compatibility with existing code

  // Cache for pages we've loaded
  final Map<int, List<Note>> _pageCache = {};

  int _totalNotes = 0;
  late final int _pageSize;

  int get totalPages => _totalNotes <= 0 ? 1 : (_totalNotes / _pageSize).ceil();

  // New property for grouped notes by date string (for current page)
  Map<String, List<Note>> _cachedGroupedNotes = {};
  List<Note> _lastGroupedNotesSource = [];
  
  /// Get grouped notes with memoization for performance
  Map<String, List<Note>> get groupedNotes {
    // Check if we need to recalculate grouping
    if (_cachedGroupedNotes.isEmpty || 
        _lastGroupedNotesSource.length != _currentPageNotes.length ||
        !_listsEqual(_lastGroupedNotesSource, _currentPageNotes)) {
      _groupNotesByDate();
      _lastGroupedNotesSource = List.from(_currentPageNotes);
    }
    return _cachedGroupedNotes;
  }

  bool _isLoadingList = false;
  bool get isLoadingList => _isLoadingList;

  bool _isLoadingAdd = false;
  bool get isLoadingAdd => _isLoadingAdd;

  String? _listError;
  String? get listError => _listError;

  String? _addError;
  String? get addError => _addError;

  // Load a specific page
  Future<void> loadPage(int pageNumber) async {
    if (_isLoadingList) return;
    if (pageNumber < 1) return;

    _isLoadingList = true;
    _listError = null;
    notifyListeners();

    try {
      // Check cache first
      if (_pageCache.containsKey(pageNumber)) {
        _currentPage = pageNumber;
        _currentPageNotes = List.from(_pageCache[pageNumber]!);
        _clearGroupedNotesCache(); // Clear cache to trigger recalculation
      } else {
        // Load from API
        final notesResult = await _notesService.myLatest(_pageSize, pageNumber);

        _currentPage = pageNumber;
        _currentPageNotes = notesResult.notes;
        _totalNotes = notesResult.totalNotes;

        // Cache the loaded page
        _pageCache[pageNumber] = List.from(notesResult.notes);

        _clearGroupedNotesCache(); // Clear cache to trigger recalculation
      }
    } on ApiException catch (e) {
      _listError = e.toString();
    } catch (e) {
      _listError = e.toString();
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  // Compatibility method for existing code
  Future<void> fetchNotes({bool loadMore = false}) async {
    await loadPage(_currentPage);
  }

  // Refresh current page (clear cache and reload)
  Future<void> refreshCurrentPage() async {
    _pageCache.remove(_currentPage);
    await loadPage(_currentPage);
  }

  /// Helper method to compare two note lists for memoization
  bool _listsEqual(List<Note> list1, List<Note> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i].id != list2[i].id || 
          list1[i].content != list2[i].content ||
          list1[i].createdAt != list2[i].createdAt) {
        return false;
      }
    }
    return true;
  }

  /// Group notes by date with caching for performance
  void _groupNotesByDate() {
    _cachedGroupedNotes = {};
    for (final note in _currentPageNotes) {
      // Use the Note entity's built-in createdDate getter for consistency
      final dateKey = note.createdDate;

      if (!_cachedGroupedNotes.containsKey(dateKey)) {
        _cachedGroupedNotes[dateKey] = [];
      }
      _cachedGroupedNotes[dateKey]!.add(note);
    }
  }

  /// Clear cached grouped notes (called when data changes)
  void _clearGroupedNotesCache() {
    _cachedGroupedNotes.clear();
    _lastGroupedNotesSource.clear();
  }

  Future<void> refreshNotes() async {
    _pageCache.clear(); // Clear all cached pages
    await loadPage(1); // Load first page
  }

  Future<Note?> addNote(String content, {bool isPrivate = false, bool isMarkdown = false, String publishDateTime = ''}) async {
    if (_isLoadingAdd) return null;

    _isLoadingAdd = true;
    _addError = null;
    notifyListeners();

    try {
      final addRequest = NoteModel(
        content: content,
        isPrivate: isPrivate,
        isMarkdown: isMarkdown,
        publishDateTime: publishDateTime,
      );

      final createdNoteId = await _notesService.post(addRequest);

      if (createdNoteId > 0) {
        // Fetch the complete note using the returned ID
        final createdNote = await _notesService.get(createdNoteId);
        
        // Optimistically add note to the beginning of page 1
        if (_currentPage == 1) {
          _currentPageNotes.insert(0, createdNote);
          // Update cache for page 1
          _pageCache[1] = List.from(_currentPageNotes);
          _clearGroupedNotesCache(); // Clear cache to trigger recalculation
          _totalNotes++;
        } else {
          // If not on page 1, just increment total count
          _totalNotes++;
        }
        
        return createdNote;
      }

      return null;
    } on ApiException catch (e) {
      _addError = e.toString();
      return null;
    } catch (e) {
      _addError = e.toString();
      return null;
    } finally {
      _isLoadingAdd = false;
      notifyListeners();
    }
  }

  Future<bool> updateNote(int noteId, String content, {bool? isPrivate, bool? isMarkdown}) async {
    final noteIndex = _currentPageNotes.indexWhere((note) => note.id == noteId);
    if (noteIndex == -1) return false; // Note not found

    try {
      final existingNote = _currentPageNotes[noteIndex];
      await _notesService.update(
        noteId,
        content,
        isPrivate ?? existingNote.isPrivate,
        isMarkdown ?? existingNote.isMarkdown
      );

      // Optimistically update the note in our list
      final updatedNote = Note(
        id: existingNote.id,
        userId: existingNote.userId,
        content: content,
        isPrivate: isPrivate ?? existingNote.isPrivate,
        isMarkdown: isMarkdown ?? existingNote.isMarkdown,
        isLong: existingNote.isLong,
        createdAt: existingNote.createdAt,
        deletedAt: existingNote.deletedAt,
        user: existingNote.user,
        tags: existingNote.tags,
      );

      _currentPageNotes[noteIndex] = updatedNote;
      _pageCache[_currentPage] = List.from(_currentPageNotes); // Update cache
      _clearGroupedNotesCache(); // Clear cache to trigger recalculation
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Note?> updateNoteAndReturn(int noteId, String content, {bool? isPrivate, bool? isMarkdown}) async {
    final noteIndex = _currentPageNotes.indexWhere((note) => note.id == noteId);
    if (noteIndex == -1) return null; // Note not found

    try {
      final existingNote = _currentPageNotes[noteIndex];
      await _notesService.update(
        noteId,
        content,
        isPrivate ?? existingNote.isPrivate,
        isMarkdown ?? existingNote.isMarkdown
      );
      
      // Optimistically update the note in our list
      final updatedNote = Note(
        id: existingNote.id,
        userId: existingNote.userId,
        content: content,
        isPrivate: isPrivate ?? existingNote.isPrivate,
        isMarkdown: isMarkdown ?? existingNote.isMarkdown,
        isLong: existingNote.isLong,
        createdAt: existingNote.createdAt,
        deletedAt: existingNote.deletedAt,
        user: existingNote.user,
        tags: existingNote.tags,
      );
      
      _currentPageNotes[noteIndex] = updatedNote;
      _pageCache[_currentPage] = List.from(_currentPageNotes); // Update cache
      _clearGroupedNotesCache(); // Clear cache to trigger recalculation
      notifyListeners();
      return updatedNote;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteNote(int noteId) async {
    try {
      await _notesService.delete(noteId);
      // Remove the note from current page
      _currentPageNotes.removeWhere((note) => note.id == noteId);
      _pageCache[_currentPage] = List.from(_currentPageNotes); // Update cache
      _totalNotes--; // Decrement total notes
      _clearGroupedNotesCache(); // Clear cache to trigger recalculation
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> undeleteNote(int noteId) async {
    try {
      await _notesService.undelete(noteId);
      // For simplicity, refresh the notes list after undelete
      await refreshNotes();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Note?> getNote(int noteId, {bool includeDeleted = false}) async {
    try {
      return await _notesService.get(noteId, includeDeleted: includeDeleted);
    } catch (e) {
      return null;
    }
  }

  /// Search notes by keyword - simplified for page-based system
  Future<void> searchNotes(String query) async {
    // For now, search will reset to show search results on current system
    // This can be enhanced later to support search pagination
    _pageCache.clear();
    await loadPage(1);
  }

  /// Get notes by tag - simplified for page-based system
  Future<void> fetchTagNotes(String tag) async {
    // For now, tag filtering will reset to show current system
    // This can be enhanced later to support tag-based pagination
    _pageCache.clear();
    await loadPage(1);
  }

  /// Clear all cached data when user logs out
  @override
  void clearAllData() {
    debugPrint('NotesProvider: Clearing all data - before: notes=${_currentPageNotes.length}, cache=${_pageCache.keys.length} pages');
    _currentPageNotes = [];
    _pageCache.clear();
    _clearGroupedNotesCache();
    _currentPage = 1;
    _totalNotes = 0;
    _isLoadingList = false;
    _isLoadingAdd = false;
    _listError = null;
    _addError = null;
    // Force immediate UI update
    notifyListeners();
    debugPrint('NotesProvider: Data cleared - after: notes=${_currentPageNotes.length}');
  }

  /// Load initial data when user logs in
  @override
  Future<void> onLogin() async {
    debugPrint('NotesProvider: Loading initial data after login');
    await loadPage(1);
  }
}