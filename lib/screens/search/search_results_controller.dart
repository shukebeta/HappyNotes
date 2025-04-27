import 'package:flutter/material.dart';
import 'package:happy_notes/entities/note.dart';
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
  String? _error;

  bool get isLoading => _isLoading;
  List<Note> get results => _results;
  String? get error => _error;

  Future<void> fetchSearchResults(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // For now, assume page 1 and default page size
      final notesResult = await _notesService.searchNotes(
          query, 0, 1); // Using 0 to trigger default size/page in API
      _results = notesResult.notes;
    } catch (e) {
      print('Error fetching search results: $e'); // Log the error
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
}
