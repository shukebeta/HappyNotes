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
  Map<String, List<Note>> groupedNotes = {};

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
        _groupNotesByDate();
      } else {
        // Load from API
        final notesResult = await _notesService.myLatest(_pageSize, pageNumber);

        _currentPage = pageNumber;
        _currentPageNotes = notesResult.notes;
        _totalNotes = notesResult.totalNotes;

        // Cache the loaded page
        _pageCache[pageNumber] = List.from(notesResult.notes);

        _groupNotesByDate();
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

  // New method to group notes by date
  void _groupNotesByDate() {
    groupedNotes = {};
    for (final note in _currentPageNotes) {
      // Use the Note entity's built-in createdDate getter for consistency
      final dateKey = note.createdDate;

      if (!groupedNotes.containsKey(dateKey)) {
        groupedNotes[dateKey] = [];
      }
      groupedNotes[dateKey]!.add(note);
    }
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

    final noteModel = NoteModel(
      content: content,
      isPrivate: isPrivate,
      isMarkdown: isMarkdown,
      publishDateTime: publishDateTime,
    );

    try {
      final noteId = await _notesService.post(noteModel);

      // Fetch the created note to get full details
      final newNote = await _notesService.get(noteId);

      // Optimistic update: Add to page 1 if we're on page 1
      if (_currentPage == 1) {
        _currentPageNotes.insert(0, newNote); // Add to beginning of page 1
        _pageCache[1] = List.from(_currentPageNotes); // Update cache
        _totalNotes++; // Increment total notes
        _groupNotesByDate(); // Update grouped notes
      }

      _isLoadingAdd = false;
      notifyListeners();
      return newNote;
    } on ApiException catch (e) {
      _addError = e.toString();
    } catch (e) {
      _addError = e.toString();
    } finally {
      _isLoadingAdd = false;
      notifyListeners();
    }
    return null;
  }

  Future<bool> updateNote(int noteId, String content, {bool? isPrivate, bool? isMarkdown}) async {
    try {
      // Find the note in current page notes
      final noteIndex = _currentPageNotes.indexWhere((note) => note.id == noteId);
      if (noteIndex == -1) return false;

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
      // Update grouped notes after modification
      _groupNotesByDate();
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteNote(int noteId) async {
    try {
      await _notesService.delete(noteId);
      // Remove the note from current page
      _currentPageNotes.removeWhere((note) => note.id == noteId);
      _pageCache[_currentPage] = List.from(_currentPageNotes); // Update cache
      _totalNotes--; // Decrement total notes
      // Update grouped notes after deletion
      _groupNotesByDate();
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
    _currentPageNotes = [];
    _pageCache.clear();
    groupedNotes = {};
    _currentPage = 1;
    _totalNotes = 0;
    _isLoadingList = false;
    _isLoadingAdd = false;
    _listError = null;
    _addError = null;
    // Force immediate UI update
    notifyListeners();
  }

  /// Load initial data when user logs in
  @override
  Future<void> onLogin() async {
    await loadPage(1);
  }
}