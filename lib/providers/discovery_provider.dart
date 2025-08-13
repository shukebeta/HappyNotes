import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/providers/note_list_provider.dart';

/// Provider for managing public notes discovery
/// Handles browsing public notes with pagination and delete operations
class DiscoveryProvider extends NoteListProvider {
  final NotesService _notesService;

  DiscoveryProvider(this._notesService);

  @override
  NotesService get notesService => _notesService;

  @override
  Future<NotesResult> fetchNotes(int pageSize, int pageNumber) async {
    return await _notesService.latest(pageSize, pageNumber);
  }

  @override
  Future<void> performDelete(int noteId) async {
    await _notesService.delete(noteId);
  }

}