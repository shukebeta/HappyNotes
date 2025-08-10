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
  static const Duration _cacheExpiration = Duration(minutes: 10);

  @override
  void clearAllData() {
    _memories.clear();
    _isLoading = false;
    _error = null;
    _lastLoadTime = null;
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

  @override
  Future<void> onLogin() async {
    // Load memories on login for immediate availability
    await loadMemories();
  }
}