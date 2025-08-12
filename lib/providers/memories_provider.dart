import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/providers/provider_base.dart';

class MemoriesProvider extends AuthAwareProvider {
  final NotesService _notesService;

  MemoriesProvider(this._notesService);

  // Memories state
  List<Note> _memories = [];
  List<Note> get memories => _memories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Cache timestamp to know when to refresh
  DateTime? _lastLoadTime;
  static const Duration _cacheExpiration = Duration(hours: 8);

  // Date-specific caching - structure: dateString -> List<Note>
  final Map<String, List<Note>> _memoriesByDateCache = {};
  
  // Loading states per date
  final Map<String, bool> _loadingStates = {};
  
  // Error states per date
  final Map<String, String?> _errorStates = {};

  // Last load time per date for cache expiration
  final Map<String, DateTime> _lastLoadTimeByDate = {};

  @override
  void clearAllData() {
    _memories.clear();
    _isLoading = false;
    _error = null;
    _lastLoadTime = null;
    _memoriesByDateCache.clear();
    _loadingStates.clear();
    _errorStates.clear();
    _lastLoadTimeByDate.clear();
    notifyListeners();
  }

  /// Load memories with caching
  Future<void> loadMemories({bool forceRefresh = false}) async {
    // Check if we should use cached data
    if (!forceRefresh && 
        _memories.isNotEmpty && 
        _error == null &&
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) < _cacheExpiration) {
      return; // Use cached data
    }

    final result = await executeWithErrorHandling<NotesResult>(
      operation: () => _notesService.memories(),
      setLoading: (loading) => _isLoading = loading,
      setError: (error) => _error = error,
      operationName: 'load memories',
    );

    if (result != null) {
      _lastLoadTime = DateTime.now();
    }

    if (result != null) {
      _memories = result.notes;
      _error = null;
      notifyListeners();
    }
  }

  /// Delete a note from memories
  Future<bool> deleteNote(int noteId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _notesService.delete(noteId);
      
      // Remove note from local memories
      _memories.removeWhere((note) => note.id == noteId);
      
      _error = null;
      return true;
    } catch (e) {
      _error = handleServiceError(e, 'delete memory note');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get memories for a specific date
  Future<NotesResult?> memoriesOn(String dateString) async {
    try {
      return await _notesService.memoriesOn(dateString);
    } catch (e) {
      handleServiceError(e, 'load memories for date');
      return null;
    }
  }

  /// Get cached memories for a specific date
  List<Note> memoriesOnDate(String dateString) {
    return _memoriesByDateCache[dateString] ?? [];
  }

  /// Check if memories are currently loading for a specific date
  bool isLoadingForDate(String dateString) {
    return _loadingStates[dateString] ?? false;
  }

  /// Get error message for a specific date, if any
  String? getErrorForDate(String dateString) {
    return _errorStates[dateString];
  }

  /// Load memories for a specific date with caching
  Future<void> loadMemoriesForDate(String dateString, {bool forceRefresh = false}) async {
    // Check if we should use cached data
    if (!forceRefresh && 
        _memoriesByDateCache[dateString]?.isNotEmpty == true &&
        _errorStates[dateString] == null &&
        _lastLoadTimeByDate[dateString] != null &&
        DateTime.now().difference(_lastLoadTimeByDate[dateString]!) < _cacheExpiration) {
      return; // Use cached data
    }

    // Prevent multiple simultaneous loads for the same date
    if (isLoadingForDate(dateString)) return;

    _setLoadingStateForDate(dateString, true);
    _clearErrorForDate(dateString);

    try {
      final result = await _notesService.memoriesOn(dateString);
      _memoriesByDateCache[dateString] = result.notes;
      _lastLoadTimeByDate[dateString] = DateTime.now();
      notifyListeners();
    } catch (error) {
      _setErrorForDate(dateString, handleServiceError(error, 'load memories for date'));
    } finally {
      _setLoadingStateForDate(dateString, false);
    }
  }

  /// Add a new memory to a specific date cache
  void addMemoryToDate(String dateString, Note newNote) {
    _memoriesByDateCache[dateString] ??= [];
    
    // Check if note already exists (avoid duplicates)
    final existingIndex = _memoriesByDateCache[dateString]!
        .indexWhere((note) => note.id == newNote.id);
    
    if (existingIndex == -1) {
      // Add new note and sort by creation date (newest first)
      _memoriesByDateCache[dateString]!.add(newNote);
      _memoriesByDateCache[dateString]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    }
  }

  /// Update a memory in a specific date cache
  void updateMemoryForDate(String dateString, Note updatedNote) {
    final notes = _memoriesByDateCache[dateString];
    if (notes == null) return;

    final index = notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      notes[index] = updatedNote;
      notifyListeners();
    }
  }

  /// Remove a memory from a specific date cache
  void removeMemoryFromDate(String dateString, int noteId) {
    final notes = _memoriesByDateCache[dateString];
    if (notes == null) return;

    final originalLength = notes.length;
    notes.removeWhere((note) => note.id == noteId);
    if (notes.length < originalLength) {
      notifyListeners();
    }
  }

  /// Set loading state for a specific date
  void _setLoadingStateForDate(String dateString, bool loading) {
    _loadingStates[dateString] = loading;
    notifyListeners();
  }

  /// Set error state for a specific date
  void _setErrorForDate(String dateString, String error) {
    _errorStates[dateString] = error;
    notifyListeners();
  }

  /// Clear error state for a specific date
  void _clearErrorForDate(String dateString) {
    _errorStates.remove(dateString);
  }

  /// Refresh memories
  Future<void> refreshMemories() async {
    await loadMemories(forceRefresh: true);
  }

  /// Check if memories are cached and fresh
  bool get hasFreshCache {
    return _memories.isNotEmpty &&
           _error == null &&
           _lastLoadTime != null &&
           DateTime.now().difference(_lastLoadTime!) < _cacheExpiration;
  }

  /// Get cache age in minutes
  int get cacheAgeMinutes {
    if (_lastLoadTime == null) return -1;
    return DateTime.now().difference(_lastLoadTime!).inMinutes;
  }

}