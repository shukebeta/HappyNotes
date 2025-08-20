import '../entities/note.dart';

/// Represents the result of a save note operation
/// This allows the controller to return operation results without directly manipulating UI
sealed class SaveNoteResult {
  const SaveNoteResult();
}

/// Save operation completed successfully
class SaveNoteSuccess extends SaveNoteResult {
  final Note savedNote;
  final SaveNoteAction action;

  const SaveNoteSuccess(this.savedNote, this.action);
}

/// Save operation failed due to validation error
class SaveNoteValidationError extends SaveNoteResult {
  final String message;

  const SaveNoteValidationError(this.message);
}

/// Save operation failed due to service error
class SaveNoteServiceError extends SaveNoteResult {
  final String message;

  const SaveNoteServiceError(this.message);
}

/// Represents the action to take after successful save
enum SaveNoteAction {
  /// Pop the current screen and return the saved note (for modal usage)
  popWithNote,

  /// Execute the callback (for main menu usage)
  executeCallback,
}

/// Represents the result of a pop handler operation
sealed class PopHandlerResult {
  const PopHandlerResult();
}

/// Should allow the pop to proceed
class PopHandlerAllow extends PopHandlerResult {
  const PopHandlerAllow();
}

/// Should prevent the pop (no action needed)
class PopHandlerPrevent extends PopHandlerResult {
  const PopHandlerPrevent();
}

/// Should show unsaved changes dialog
class PopHandlerShowDialog extends PopHandlerResult {
  final String content;
  final String initialContent;

  const PopHandlerShowDialog(this.content, this.initialContent);
}
