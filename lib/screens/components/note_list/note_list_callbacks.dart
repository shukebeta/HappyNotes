import '../../../entities/note.dart';

class NoteListCallbacks {
  final void Function(Note note, String tag)? onTagTap;
  final Future<void> Function()? onRefresh;
  final void Function(DateTime date)? onDateHeaderTap;

  const NoteListCallbacks({
    this.onTagTap,
    this.onRefresh,
    this.onDateHeaderTap,
  });
}