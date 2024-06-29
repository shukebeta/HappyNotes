import '../entities/note.dart';

class NotesResult {
  List<Note> notes;
  int totalNotes;
  NotesResult(this.notes, this.totalNotes);
}