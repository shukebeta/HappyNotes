import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/providers/app_state_provider.dart';
import 'package:happy_notes/utils/app_logger_interface.dart';

/// Coordinator service for updating note caches across all relevant providers
/// 
/// This service provides a centralized way to notify all NoteListProvider instances
/// when a note has been updated, ensuring data consistency across the application
/// without tight coupling between NoteDetail and specific providers.
class NoteUpdateCoordinator {
  final AppStateProvider _appStateProvider;
  final AppLoggerInterface _logger;

  NoteUpdateCoordinator({
    required AppStateProvider appStateProvider,
    required AppLoggerInterface logger,
  })  : _appStateProvider = appStateProvider,
        _logger = logger;

  /// Notify all relevant providers that a note has been updated
  /// 
  /// This method will call updateLocalCache on all NoteListProvider instances
  /// that are currently instantiated. Providers handle existence checking
  /// internally, so it's safe to call this for all providers.
  void notifyNoteUpdated(Note updatedNote) {
    _logger.d('NoteUpdateCoordinator.notifyNoteUpdated called: noteId=${updatedNote.id}');
    
    try {
      _appStateProvider.notifyNoteUpdated(updatedNote);
      _logger.d('NoteUpdateCoordinator.notifyNoteUpdated completed successfully');
    } catch (e) {
      _logger.e('NoteUpdateCoordinator.notifyNoteUpdated error: $e');
      rethrow;
    }
  }
}