import 'package:flutter/material.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/app_config.dart'; // Import AppConfig for pageSize
import 'package:happy_notes/services/notes_services.dart';
// import 'package:happy_notes/dependency_injection.dart'; // Needed if service is injected via constructor/locator
import 'package:happy_notes/services/note_tag_service.dart'; // Import NoteTagService
import 'package:happy_notes/utils/util.dart'; // Import Util for error handling

class SearchResultsController extends ChangeNotifier {
  final NotesService _notesService;
  final NoteTagService _noteTagService; // Add NoteTagService

  // Constructor to accept NotesService
  SearchResultsController(
      {required NotesService notesService,
      required NoteTagService noteTagService}) // Update constructor
      : _notesService = notesService,
        _noteTagService = noteTagService;

  bool _isLoading = false;
  List<Note> _results = [];
  int _totalCount = 0;
  int _currentPage = 1; // Keep track of the current page
  String? _error;

  bool get isLoading => _isLoading;
  List<Note> get results => _results;
  String? get error => _error;
  int get totalNotes =>
      _totalCount <= 0 ? 1 : _totalCount; // Avoid division by zero
  int get totalPages => (totalNotes / AppConfig.pageSize).ceil();
  int get currentPage => _currentPage;

  // Modify fetchSearchResults to accept page number
  Future<void> fetchSearchResults(String query, int pageNumber) async {
    _isLoading = true;
    _error = null;
    // Don't clear results immediately, wait for new results or error
    // _results = [];
    notifyListeners();

    try {
      // Use AppConfig.pageSize and the provided pageNumber
      final notesResult = await _notesService.searchNotes(
          query, AppConfig.pageSize, pageNumber);
      // Update state with results and pagination info
      _results = notesResult.notes;
      _totalCount = notesResult.totalNotes;
      _currentPage = pageNumber; // Store the fetched page number
    } catch (e) {
      _error = 'Failed to fetch search results: $e';
      _results = []; // Clear results on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add loadTagCloud method (similar to HomePageController)
  Future<Map<String, int>> loadTagCloud(BuildContext context) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      // Consider if a separate loading state is needed for tag cloud
      final tagCloud = await _noteTagService.getMyTagCloud();
      return {for (var item in tagCloud) item.tag: item.count};
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    } finally {
      // Handle loading state if needed
    }
    return {};
  }

  Future<void> deleteNote(BuildContext context, int noteId) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _notesService.delete(noteId);
      // Remove the note from the local list and update count
      _results.removeWhere((note) => note.id == noteId);
      _totalCount--; // Decrement total count
      // Optionally, show a success message
      Util.showInfo(scaffoldContext, 'Note deleted successfully.');
    } catch (error) {
      _error = 'Failed to delete note: $error';
      Util.showError(scaffoldContext, _error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
