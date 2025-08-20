import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/providers/note_list_provider.dart';
import 'package:happy_notes/utils/operation_result.dart';

class TagNotesProvider extends NoteListProvider {
  final NotesService _notesService;

  TagNotesProvider(this._notesService);

  @override
  NotesService get notesService => _notesService;

  // Tag-specific state
  String _currentTag = '';
  String get currentTag => _currentTag;

  // Alias for compatibility
  List<Note> get tagNotes => notes;

  @override
  void clearNotesCache() {
    _currentTag = '';
    super.clearNotesCache();
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
    super.clearNotesCache();
  }

  @override
  Future<OperationResult<void>> deleteNote(int noteId) async {
    return await super.deleteNote(noteId);
  }

  /// Refresh current tag notes
  Future<void> refreshTagNotes() async {
    if (_currentTag.isNotEmpty) {
      await refresh();
    }
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