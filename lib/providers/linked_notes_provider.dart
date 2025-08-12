import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/providers/provider_base.dart';

/// Provider for managing linked notes functionality
/// Handles caching and state management for notes linked via @noteId tags
class LinkedNotesProvider extends AuthAwareProvider {
  final NotesService _notesService;

  LinkedNotesProvider(this._notesService);

  // Cache structure: parentNoteId -> List<Note>
  final Map<int, List<Note>> _linkedNotesCache = {};

  // Loading states per parent note
  final Map<int, bool> _loadingStates = {};

  // Error states per parent note
  final Map<int, String?> _errorStates = {};

  /// Get cached linked notes for a parent note
  List<Note> getLinkedNotes(int parentNoteId) {
    return _linkedNotesCache[parentNoteId] ?? [];
  }

  /// Check if linked notes are currently loading for a parent note
  bool isLoading(int parentNoteId) {
    return _loadingStates[parentNoteId] ?? false;
  }

  /// Get error message for a parent note, if any
  String? getError(int parentNoteId) {
    return _errorStates[parentNoteId];
  }

  /// Load linked notes for a parent note
  Future<void> loadLinkedNotes(int parentNoteId) async {
    // Prevent multiple simultaneous loads for the same parent note
    if (isLoading(parentNoteId)) return;

    _setLoadingState(parentNoteId, true);
    _clearError(parentNoteId);

    try {
      final result = await _notesService.getLinkedNotes(parentNoteId);
      _linkedNotesCache[parentNoteId] = result.notes;
      notifyListeners();
    } catch (error) {
      _setError(parentNoteId, handleServiceError(error, 'load linked notes'));
    } finally {
      _setLoadingState(parentNoteId, false);
    }
  }

  /// Refresh linked notes for a parent note (force reload from server)
  Future<void> refreshLinkedNotes(int parentNoteId) async {
    // Clear cache first to ensure fresh data
    _linkedNotesCache.remove(parentNoteId);
    await loadLinkedNotes(parentNoteId);
  }

  /// Update a linked note in cache
  /// Only called when current user updates their own note
  void updateLinkedNote(int parentNoteId, Note updatedNote) {
    final notes = _linkedNotesCache[parentNoteId];
    if (notes == null) return;

    // Check if the note still has the linking tag
    final hasLinkingTag = updatedNote.tags?.any((tag) => tag == '@$parentNoteId') ?? false;

    if (hasLinkingTag) {
      // Update the note in cache
      final index = notes.indexWhere((note) => note.id == updatedNote.id);
      if (index != -1) {
        notes[index] = updatedNote;
        notifyListeners();
      }
    } else {
      // User removed the linking tag, remove from cache
      removeLinkedNote(parentNoteId, updatedNote.id);
    }
  }

  /// Add a new linked note to cache
  void addLinkedNote(int parentNoteId, Note newNote) {
    // Ensure the note has the correct linking tag
    final hasLinkingTag = newNote.tags?.any((tag) => tag == '@$parentNoteId') ?? false;
    if (!hasLinkingTag) return;

    _linkedNotesCache[parentNoteId] ??= [];

    // Check if note already exists (avoid duplicates)
    final existingIndex = _linkedNotesCache[parentNoteId]!
        .indexWhere((note) => note.id == newNote.id);

    if (existingIndex == -1) {
      // Add new note and sort by creation date (newest first)
      _linkedNotesCache[parentNoteId]!.add(newNote);
      _linkedNotesCache[parentNoteId]!.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    }
  }

  /// Remove a linked note from cache
  void removeLinkedNote(int parentNoteId, int noteId) {
    final notes = _linkedNotesCache[parentNoteId];
    if (notes == null) return;

    final originalLength = notes.length;
    notes.removeWhere((note) => note.id == noteId);
    if (notes.length < originalLength) {
      notifyListeners();
    }
  }

  /// Set loading state for a parent note
  void _setLoadingState(int parentNoteId, bool loading) {
    _loadingStates[parentNoteId] = loading;
    notifyListeners();
  }

  /// Set error state for a parent note
  void _setError(int parentNoteId, String error) {
    _errorStates[parentNoteId] = error;
    notifyListeners();
  }

  /// Clear error state for a parent note
  void _clearError(int parentNoteId) {
    _errorStates.remove(parentNoteId);
  }

  @override
  void clearAllData() {
    _linkedNotesCache.clear();
    _loadingStates.clear();
    _errorStates.clear();
    notifyListeners();
  }
}