/// Result data structure returned by NoteDetail when editing is complete
/// 
/// This encapsulates all the editing results without coupling NoteDetail
/// to any specific data persistence logic.
class NoteEditResult {
  /// The edited content of the note
  final String content;
  
  /// Whether the note should be private
  final bool isPrivate;
  
  /// Whether the note uses markdown formatting
  final bool isMarkdown;
  
  /// Whether the user chose to save the changes (true) or cancel (false)
  final bool isSaved;

  const NoteEditResult({
    required this.content,
    required this.isPrivate,
    required this.isMarkdown,
    required this.isSaved,
  });

  /// Create a result for when user cancels editing
  const NoteEditResult.cancelled({
    required this.content,
    required this.isPrivate,
    required this.isMarkdown,
  }) : isSaved = false;

  /// Create a result for when user saves changes
  const NoteEditResult.saved({
    required this.content,
    required this.isPrivate,
    required this.isMarkdown,
  }) : isSaved = true;

  @override
  String toString() {
    return 'NoteEditResult{'
        'content: "${content.length} chars", '
        'isPrivate: $isPrivate, '
        'isMarkdown: $isMarkdown, '
        'isSaved: $isSaved'
        '}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteEditResult &&
          runtimeType == other.runtimeType &&
          content == other.content &&
          isPrivate == other.isPrivate &&
          isMarkdown == other.isMarkdown &&
          isSaved == other.isSaved;

  @override
  int get hashCode =>
      content.hashCode ^
      isPrivate.hashCode ^
      isMarkdown.hashCode ^
      isSaved.hashCode;
}