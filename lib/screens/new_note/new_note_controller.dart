import '../../models/note_model.dart';
import '../../models/save_note_result.dart';
import '../../providers/notes_provider.dart';

class NewNoteController {
  NewNoteController();

  /// New save note method without BuildContext dependency
  /// Returns SaveNoteResult for UI layer to handle
  Future<SaveNoteResult> saveNoteAsync(
    NoteModel noteModel,
    NotesProvider notesProvider, {
    bool useCallback = false,
  }) async {
    // Validate input
    if (noteModel.content.trim().isEmpty) {
      return const SaveNoteValidationError('Please write something');
    }

    try {
      // Use NotesProvider.addNote for consistency
      final savedNote = await notesProvider.addNote(
        noteModel.content,
        isPrivate: noteModel.isPrivate,
        isMarkdown: noteModel.isMarkdown,
        publishDateTime: noteModel.publishDateTime,
      );

      if (savedNote != null) {
        // Clear the note model
        noteModel.initialContent = '';
        noteModel.content = '';
        noteModel.unfocus();

        // Determine the action based on usage context
        final action = useCallback ? SaveNoteAction.executeCallback : SaveNoteAction.popWithNote;

        return SaveNoteSuccess(savedNote, action);
      } else {
        // Handle case where addNote returned null (failed)
        final errorMessage = notesProvider.addError ?? 'Failed to save note';
        return SaveNoteServiceError(errorMessage);
      }
    } catch (e) {
      return SaveNoteServiceError('Failed to save note: $e');
    }
  }

  /// New pop handler method without BuildContext dependency
  /// Returns PopHandlerResult for UI layer to handle
  PopHandlerResult handlePopAsync(NoteModel noteModel, bool didPop) {
    if (!didPop) {
      if (noteModel.content.isEmpty || noteModel.content.trim() == noteModel.initialContent.trim()) {
        return const PopHandlerAllow();
      } else {
        return PopHandlerShowDialog(noteModel.content, noteModel.initialContent);
      }
    }
    return const PopHandlerPrevent();
  }
}
