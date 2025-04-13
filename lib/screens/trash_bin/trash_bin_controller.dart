import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/dependency_injection.dart';
import 'package:happy_notes/entities/note.dart';
import '../../app_config.dart';

class TrashBinController {
  final NotesService _notesService = locator<NotesService>();
  List<Note> _trashedNotes = [];
  int _currentPageNumber = 1;
  int _totalPages = 1;
  bool _isPurging = false;
  bool _isLoading = true;

  List<Note> get trashedNotes => _trashedNotes;
  int get currentPageNumber => _currentPageNumber;
  int get totalPages => _totalPages;
  bool get isPurging => _isPurging;
  bool get isLoading => _isLoading;

  Future<void> fetchTrashedNotes() async {
    setIsLoading(true);
    try {
      var result = await _notesService.latestDeleted(AppConfig.pageSize, _currentPageNumber);
      _trashedNotes = result.notes;
      _totalPages = (result.totalNotes / AppConfig.pageSize).ceil();
    } catch (e) {
      // Handle error
    } finally {
      setIsLoading(false);
    }
  }

  void setIsLoading(bool loading) {
    _isLoading = loading;
  }

  Future<void> purgeDeleted() async {
    _isPurging = true;
    try {
      await _notesService.purgeDeleted();
    } catch (e) {
      // Handle error
    } finally {
      _isPurging = false;
      await fetchTrashedNotes();
    }
  }

  Future<void> undeleteNote(int noteId) async {
    try {
      await _notesService.undelete(noteId);
      await fetchTrashedNotes();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> navigateToPage(int pageNumber) async {
    _currentPageNumber = pageNumber;
    await fetchTrashedNotes();
  }

  Future<Note> getNote(int noteId) async {
    return await _notesService.get(noteId, includeDeleted: true);
  }
}
