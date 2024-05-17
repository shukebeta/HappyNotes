import 'package:HappyNotes/results/notes_result.dart';

import '../entities/note.dart';
import '../services/notes_services.dart';

class NotesModel {
  static Future<NotesResult> fetchLatestNotes(int pageSize, int pageNumber) async {
    var apiResult = await NotesService.latest(pageSize, pageNumber);
    return _getNotesResult(apiResult);
  }

  static Future<NotesResult> fetchMyLatestNotes(int pageSize, int pageNumber) async {
    var apiResult = await NotesService.myLatest(pageSize, pageNumber);
    return _getNotesResult(apiResult);
  }

  static NotesResult _getNotesResult(apiResult) {
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    var notes = apiResult['data'];
    int totalNotes = notes['totalCount'];
    List<dynamic> fetchedNotesData = notes['dataList'];
    List<Note> fetchedNotes = fetchedNotesData.map((json) => Note.fromJson(json)).toList();
    return NotesResult(fetchedNotes, totalNotes);
  }

  static Future<int> post(String note, bool isPrivate) async{
    var apiResult = await NotesService.post(note, isPrivate);
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    return apiResult['data']; //note id
  }
}
