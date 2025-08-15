import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/providers/provider_base.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/utils/operation_result.dart';
import 'package:happy_notes/utils/app_logger_interface.dart';
import 'package:get_it/get_it.dart';
import '../screens/components/list_grouper.dart';

/// Abstract base class for providers that manage paginated note lists with date grouping
abstract class NoteListProvider extends AuthAwareProvider {
  NoteListProvider() {
    try {
      _pageSize = AppConfig.pageSize;
    } catch (e) {
      _pageSize = 10; // Default for tests
    }
  }

  // Note list state
  List<Note> _notes = [];
  List<Note> get notes => _notes;

  // Pagination state
  int _currentPage = 1;
  int get currentPage => _currentPage;

  int _totalNotes = 0;
  late final int _pageSize;

  // Computed properties
  int get totalPages => _totalNotes <= 0 ? 1 : (_totalNotes / _pageSize).ceil();

  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Date grouping - automatically computed from notes
  Map<String, List<Note>> get groupedNotes {
    return ListGrouper.groupByDate(_notes, (note) => note.createdDate);
  }

  /// Abstract method that subclasses must implement to fetch notes
  /// This should call the appropriate service method for the specific note type
  Future<NotesResult> fetchNotes(int pageSize, int pageNumber);

  /// Abstract getter that subclasses must implement to provide NotesService
  NotesService get notesService;

  /// Navigate to a specific page
  Future<void> navigateToPage(int pageNumber) async {
    if (pageNumber < 1 || pageNumber > totalPages || _isLoading) return;

    final result = await executeWithErrorHandling<NotesResult>(
      operation: () => fetchNotes(_pageSize, pageNumber),
      setLoading: (loading) => _isLoading = loading,
      setError: (error) => _error = error,
      operationName: 'load page $pageNumber',
    );

    if (result != null) {
      _currentPage = pageNumber;
      _notes = result.notes;
      _totalNotes = result.totalNotes;
      _error = null;
      notifyListeners();
    }
  }

  /// Refresh current page
  Future<void> refresh() async {
    await navigateToPage(_currentPage);
  }

  /// Delete a note with optimistic updates and rollback on failure
  Future<OperationResult<void>> deleteNote(int noteId) async {
    // Store original state for rollback
    final originalNotes = List<Note>.from(_notes);
    final originalTotalNotes = _totalNotes;

    // Optimistic update - remove note immediately
    _notes.removeWhere((note) => note.id == noteId);
    if (_totalNotes > 0) _totalNotes--;

    notifyListeners(); // Show optimistic update immediately

    try {
      // Call the delete service (subclasses can override this if needed)
      await performDelete(noteId);
      return OperationResult.success(null);
    } catch (e) {
      // Rollback optimistic updates on failure
      _notes = originalNotes;
      _totalNotes = originalTotalNotes;
      notifyListeners();

      final errorMessage = handleServiceError(e, 'delete note');
      return OperationResult.error(errorMessage);
    }
  }

  /// Abstract method for performing the actual delete operation
  /// Subclasses should implement this to call the appropriate service method
  Future<void> performDelete(int noteId);

  /// Update note in local cache - pure client-side operation
  void updateLocalCache(Note updatedNote) {
    final logger = GetIt.instance<AppLoggerInterface>();
    final noteIndex = notes.indexWhere((note) => note.id == updatedNote.id);
    
    logger.d('NoteListProvider.updateLocalCache called: noteId=${updatedNote.id}, noteIndex=$noteIndex');
    
    if (noteIndex != -1) {
      notes[noteIndex] = updatedNote;
      notifyListeners();
      logger.d('NoteListProvider.updateLocalCache updated cache and notified listeners');
    } else {
      logger.d('NoteListProvider.updateLocalCache note not in cache, skipping update');
    }
  }

  /// Legacy updateNote method - kept for backward compatibility in tests
  /// This method is deprecated - use updateLocalCache instead
  @Deprecated('Use updateLocalCache instead')
  Future<Note?> updateNote(int noteId, String content, {required bool isPrivate, required bool isMarkdown}) async {
    final logger = GetIt.instance<AppLoggerInterface>();
    final noteIndex = notes.indexWhere((note) => note.id == noteId);
    
    logger.d('NoteListProvider.updateNote called: noteId=$noteId, noteIndex=$noteIndex, content length=${content.length}');
    
    try {
      final updatedNote = await notesService.update(
        noteId,
        content,
        isPrivate,
        isMarkdown
      );
      
      if (noteIndex != -1) {
        notes[noteIndex] = updatedNote;
        notifyListeners();
      }
      
      return updatedNote;
    } catch (e) {
      logger.e('NoteListProvider.updateNote error: $e for noteId=$noteId');
      return null;
    }
  }


  @override
  void clearAllData() {
    _notes.clear();
    _currentPage = 1;
    _totalNotes = 0;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// Load initial data - called by onLogin in AuthAwareProvider
  Future<void> loadInitialData() async {
    if (_notes.isEmpty) {
      await navigateToPage(1);
    }
  }
}