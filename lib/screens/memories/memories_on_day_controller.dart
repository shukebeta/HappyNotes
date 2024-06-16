import 'package:happy_notes/results/notes_result.dart';
import 'package:intl/intl.dart';
import '../../services/notes_services.dart';

class MemoriesOnDayController {
  final NotesService _notesService;

  MemoriesOnDayController({required NotesService notesService})
      : _notesService = notesService;

  Future<NotesResult> fetchMemories(DateTime date) async {
    var notes = await _notesService.memoriesOn(DateFormat('yyyyMMdd').format(date));
    return notes;
  }
}
