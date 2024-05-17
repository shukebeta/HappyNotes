import 'package:HappyNotes/apis/notes_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../entities/note.dart';
import '../results/notes_result.dart';

class NotesService {
  static Future<NotesResult> latest(int pageSize, int pageNumber) async {
    var params = {'pageSize': pageSize, 'pageNumber': pageNumber};
    var apiResult = (await NotesApi.latest(params)).data;
    return _getNotesResult(apiResult);
  }

  static Future<NotesResult> myLatest(int pageSize, int pageNumber) async {
    var params = {'pageSize': pageSize, 'pageNumber': pageNumber};
    var apiResult = (await NotesApi.myLatest(params)).data;
    return _getNotesResult(apiResult);
  }

  static Future<int> post(String content, bool isPrivate) async {
    var params = {'content': content, 'isPrivate': isPrivate};
    var apiResult = (await NotesApi.post(params)).data;
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    return apiResult['data']; //note id
  }

  static Future<dynamic> update(int noteId, String content) async {
    var params = {'id': noteId, 'content': content};
    return (await NotesApi.update(params)).data;
  }

  static NotesResult _getNotesResult(apiResult) {
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    var notes = apiResult['data'];
    int totalNotes = notes['totalCount'];
    List<dynamic> fetchedNotesData = notes['dataList'];
    List<Note> fetchedNotes = fetchedNotesData.map((json) => Note.fromJson(json)).toList();
    return NotesResult(fetchedNotes, totalNotes);
  }

}

