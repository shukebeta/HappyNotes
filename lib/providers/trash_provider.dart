import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/providers/note_list_provider.dart';

/// Provider for managing trash bin functionality
/// Handles deleted notes with pagination, purge, and undelete operations
class TrashProvider extends NoteListProvider {
  final NotesService _notesService;

  bool _isPurging = false;

  TrashProvider(this._notesService);

  @override
  NotesService get notesService => _notesService;

  // Additional getters for trash-specific functionality
  List<Note> get trashedNotes => notes; // Alias for compatibility
  bool get isPurging => _isPurging;

  @override
  Future<NotesResult> fetchNotes(int pageSize, int pageNumber) async {
    return await _notesService.latestDeleted(pageSize, pageNumber);
  }

  @override
  Future<void> performDelete(int noteId) async {
    // For trash, "delete" means permanently delete (not implemented here)
    // This shouldn't be called for trash items
    throw UnimplementedError('Use purgeDeleted or undeleteNote instead');
  }

  /// Purge all deleted notes permanently
  Future<bool> purgeDeleted() async {
    _isPurging = true;
    notifyListeners();

    try {
      await _notesService.purgeDeleted();

      // Refresh the list after purge
      await refresh();

      return true;
    } catch (e) {
      // Handle error using base class method
      handleServiceError(e, 'purge deleted notes');
      return false;
    } finally {
      _isPurging = false;
      notifyListeners();
    }
  }

  /// Undelete a note (restore from trash)
  Future<bool> undeleteNote(int noteId) async {
    try {
      await _notesService.undelete(noteId);

      // Remove the note from local cache immediately
      notes.removeWhere((note) => note.id == noteId);

      // Refresh to get updated totals
      await refresh();

      return true;
    } catch (e) {
      handleServiceError(e, 'undelete note');
      return false;
    }
  }

  /// Get a specific note (including deleted ones)
  Future<Note?> getNote(int noteId) async {
    try {
      return await _notesService.get(noteId);
    } catch (e) {
      handleServiceError(e, 'get deleted note');
      return null;
    }
  }


  @override
  void clearAllData() {
    _isPurging = false;
    super.clearAllData();
  }
}