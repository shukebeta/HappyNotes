import 'package:flutter/material.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/services/notes_services.dart';
// import 'package:happy_notes/dependency_injection.dart'; // Needed if service is injected via constructor/locator

class SearchResultsController extends ChangeNotifier {
  final NotesService _notesService;

  // Constructor to accept NotesService
  SearchResultsController({required NotesService notesService})
      : _notesService = notesService;

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
}
