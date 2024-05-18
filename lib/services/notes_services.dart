import 'package:HappyNotes/apis/notes_api.dart';
import '../entities/note.dart';
import '../results/notes_result.dart';

class NotesService {
  // fetch all public notes from all users
  static Future<NotesResult> latest(int pageSize, int pageNumber) async {
    var params = {'pageSize': pageSize, 'pageNumber': pageNumber};
    var apiResult = (await NotesApi.latest(params)).data;
    return _getNotesResult(apiResult);
  }

  // fetch my latest notes (include private ones)
  static Future<NotesResult> myLatest(int pageSize, int pageNumber) async {
    var params = {'pageSize': pageSize, 'pageNumber': pageNumber};
    var apiResult = (await NotesApi.myLatest(params)).data;
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

  // post a note and get its noteId
  static Future<int> post(String content, bool isPrivate) async {
    var params = {'content': content, 'isPrivate': isPrivate};
    var apiResult = (await NotesApi.post(params)).data;
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    return apiResult['data']; //note id
  }

  // update a note and get its noteId
  static Future<int> update(int noteId, String content, bool isPrivate) async {
    var params = {'id': noteId, 'content': content, 'isPrivate': isPrivate};
    var apiResult = (await NotesApi.update(params)).data;
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    return apiResult['data']; //note id
  }

  static Future<int> delete(int noteId) async {
    var apiResult = (await NotesApi.delete(noteId)).data;
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    return apiResult['data']; //note id
  }

  static Future<int> undelete(int noteId) async {
    var apiResult = (await NotesApi.undelete(noteId)).data;
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    return apiResult['data']; //note id
  }

  static Future<Note> get(int noteId) async {
    var apiResult = (await NotesApi.get(noteId)).data;
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    return Note.fromJson(apiResult['data']); //note id
  }

}

