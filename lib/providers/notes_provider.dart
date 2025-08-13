import 'package:flutter/foundation.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/note_model.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/providers/note_list_provider.dart';
import 'package:happy_notes/exceptions/api_exception.dart';

class NotesProvider extends NoteListProvider {
  final NotesService _notesService;

  NotesProvider(this._notesService);

  @override
  NotesService get notesService => _notesService;

  // Loading state for add operations
  bool _isLoadingAdd = false;
  bool get isLoadingAdd => _isLoadingAdd;

  String? _addError;
  String? get addError => _addError;

  // Compatibility getters for existing UI code
  bool get isLoadingList => isLoading;
  String? get listError => error;

  /// Implement abstract method from NoteListProvider
  @override
  Future<NotesResult> fetchNotes(int pageSize, int pageNumber) async {
    return await _notesService.myLatest(pageSize, pageNumber);
  }

  /// Implement abstract method from NoteListProvider
  @override
  Future<void> performDelete(int noteId) async {
    await _notesService.delete(noteId);
  }

  /// Compatibility method for existing code
  Future<void> loadPage(int pageNumber) async {
    await navigateToPage(pageNumber);
  }

  /// Compatibility method for existing code (no parameters)
  Future<void> fetchNotesLegacy() async {
    await refresh();
  }

  /// Compatibility method for existing code
  Future<void> refreshCurrentPage() async {
    await refresh();
  }

  /// Compatibility method for existing code
  Future<void> refreshNotes() async {
    await refresh();
  }

  /// Add a new note with optimistic updates
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

      final createdNote = await _notesService.post(addRequest);

      // Optimistically add note to the beginning if on page 1
      if (currentPage == 1) {
        notes.insert(0, createdNote);
        notifyListeners();
      }

      return createdNote;
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





  /// Undelete a note
  Future<bool> undeleteNote(int noteId) async {
    try {
      await _notesService.undelete(noteId);
      // Refresh the notes list after undelete
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get a specific note by ID
  Future<Note?> getNote(int noteId, {bool includeDeleted = false}) async {
    try {
      return await _notesService.get(noteId, includeDeleted: includeDeleted);
    } catch (e) {
      return null;
    }
  }

  /// Search notes by keyword
  Future<void> searchNotes(String query) async {
    // For now, search will reset to show search results on current system
    // This can be enhanced later to support search pagination
    await refresh();
  }

  /// Get notes by tag
  Future<void> fetchTagNotes(String tag) async {
    // For now, tag filtering will reset to show current system
    // This can be enhanced later to support tag-based pagination
    await refresh();
  }

  @override
  void clearAllData() {
    debugPrint('NotesProvider: Clearing all data');
    _isLoadingAdd = false;
    _addError = null;
    super.clearAllData();
    debugPrint('NotesProvider: Data cleared');
  }

  /// Load initial data when user logs in
  @override
  Future<void> onLogin() async {
    debugPrint('NotesProvider: Loading initial data after login');
    await loadInitialData();
  }
}