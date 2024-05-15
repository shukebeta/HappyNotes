import 'package:HappyNotes/results/notes_result.dart';

import '../entities/note.dart';
import '../services/notes_services.dart';

class NotesModel {
  Future<NotesResult> fetchLatestNotes(int pageSize, int pageNumber) async {
    var apiResult = await NotesService.latest(pageSize, pageNumber);
    return _getNotesResult(apiResult);
  }

  Future<NotesResult> fetchMyLatestNotes(int pageSize, int pageNumber) async {
    var apiResult = await NotesService.myLatest(pageSize, pageNumber);
    return _getNotesResult(apiResult);
  }

  NotesResult _getNotesResult(apiResult) {
    int totalNotes = apiResult['totalCount'];
    List<dynamic> fetchedNotesData = apiResult['dataList'];
    List<Note> fetchedNotes = fetchedNotesData.map((json) => Note.fromJson(json)).toList();
    return NotesResult(fetchedNotes, totalNotes);
  }
}
