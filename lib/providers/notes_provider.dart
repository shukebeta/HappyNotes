import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/note_model.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/utils/util.dart';
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

  List<Note> _notes = [];
  List<Note> get notes => _notes;

  // New property for grouped notes by date string
  Map<String, List<Note>> groupedNotes = {};

  bool _isLoadingList = false;
  bool get isLoadingList => _isLoadingList;

  bool _isLoadingAdd = false;
  bool get isLoadingAdd => _isLoadingAdd;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  String? _listError;
  String? get listError => _listError;

  String? _addError;
  String? get addError => _addError;

  int _currentPage = 1;
  int _totalNotes = 0;
  late final int _pageSize;

  bool get canLoadMore => _notes.length < _totalNotes;

  Future<void> fetchNotes({bool loadMore = false}) async {
    if (_isLoadingList) return;
    if (loadMore && !canLoadMore) return;

    _isLoadingList = true;
    _listError = null;
    if (!loadMore) {
      _currentPage = 1;
      _notes = [];
      groupedNotes = {}; // Reset grouped notes when refreshing
    }
    notifyListeners();

    try {
      final notesResult = await _notesService.myLatest(_pageSize, _currentPage);
      
      if (loadMore) {
        _notes.addAll(notesResult.notes);
      } else {
        _notes = notesResult.notes;
      }
      _totalNotes = notesResult.totalNotes;
      if (notesResult.notes.isNotEmpty) {
        _currentPage++; // Increment current page if data was fetched
      }

      // Group notes by date after updating the list
      _groupNotesByDate();
    } on ApiException catch (e) {
      _listError = e.toString();
    } catch (e) {
      _listError = e.toString();
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  // New method to group notes by date
  void _groupNotesByDate() {
    groupedNotes = {};
    for (final note in _notes) {
      // Format the createdAt timestamp to local date string using 'yyyy-MM-dd' format
      final dateKey = Util.formatUnixTimestampToLocalDate(
        (note.createdAt / 1000).round(),
        'yyyy-MM-dd',
      );

      if (!groupedNotes.containsKey(dateKey)) {
        groupedNotes[dateKey] = [];
      }
      groupedNotes[dateKey]!.add(note);
    }
  }

  Future<void> refreshNotes() async {
    _currentPage = 1;
    _notes = [];
    groupedNotes = {}; // Clear grouped notes when refreshing
    await fetchNotes();
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
      
      // Add to the beginning of the list (most recent first)
      _notes.insert(0, newNote);
      _totalNotes++; // Increment total notes
      // Update grouped notes after adding new note
      _groupNotesByDate();
      
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
      // Find the note in our list
      final noteIndex = _notes.indexWhere((note) => note.id == noteId);
      if (noteIndex == -1) return false;

      final existingNote = _notes[noteIndex];
      
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

      _notes[noteIndex] = updatedNote;
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
      // Remove the note from the list
      _notes.removeWhere((note) => note.id == noteId);
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

  /// Search notes by keyword
  Future<void> searchNotes(String query, {bool loadMore = false}) async {
    if (_isLoadingList) return;
    if (loadMore && !canLoadMore) return;

    _isLoadingList = true;
    _listError = null;
    if (!loadMore) {
      _currentPage = 1;
      _notes = [];
      groupedNotes = {};
    }
    notifyListeners();

    try {
      final notesResult = await _notesService.searchNotes(query, _pageSize, _currentPage);
      
      if (loadMore) {
        _notes.addAll(notesResult.notes);
      } else {
        _notes = notesResult.notes;
      }
      _totalNotes = notesResult.totalNotes;
      if (notesResult.notes.isNotEmpty) {
        _currentPage++;
      }

      _groupNotesByDate();
    } on ApiException catch (e) {
      _listError = e.toString();
    } catch (e) {
      _listError = e.toString();
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  /// Get notes by tag
  Future<void> fetchTagNotes(String tag, {bool loadMore = false}) async {
    if (_isLoadingList) return;
    if (loadMore && !canLoadMore) return;

    _isLoadingList = true;
    _listError = null;
    if (!loadMore) {
      _currentPage = 1;
      _notes = [];
      groupedNotes = {};
    }
    notifyListeners();

    try {
      final notesResult = await _notesService.tagNotes(tag, _pageSize, _currentPage);
      
      if (loadMore) {
        _notes.addAll(notesResult.notes);
      } else {
        _notes = notesResult.notes;
      }
      _totalNotes = notesResult.totalNotes;
      if (notesResult.notes.isNotEmpty) {
        _currentPage++;
      }

      _groupNotesByDate();
    } on ApiException catch (e) {
      _listError = e.toString();
    } catch (e) {
      _listError = e.toString();
    } finally {
      _isLoadingList = false;
      notifyListeners();
    }
  }

  /// Clear all cached data when user logs out
  @override
  void clearAllData() {
    _notes = [];
    groupedNotes = {};
    _isLoadingList = false;
    _isLoadingAdd = false;
    _isRefreshing = false;
    _listError = null;
    _addError = null;
    _currentPage = 1;
    _totalNotes = 0;
    // Force immediate UI update
    notifyListeners();
  }

  /// Load initial data when user logs in
  @override
  Future<void> onLogin() async {
    await fetchNotes();
  }
}