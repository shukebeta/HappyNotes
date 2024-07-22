import 'package:happy_notes/apis/notes_api.dart';
import '../app_config.dart';
import '../entities/note.dart';
import '../exceptions/api_exception.dart';
import '../models/notes_result.dart';

class NotesService {
  // fetch all public notes from all users
  Future<NotesResult> latest(int pageSize, int pageNumber) async {
    var params = {'pageSize': pageSize, 'pageNumber': pageNumber};
    var apiResult = (await NotesApi.latest(params)).data;
    return _getPagedNotesResult(apiResult);
  }

  // fetch my latest notes (include private ones)
  Future<NotesResult> myLatest(int pageSize, int pageNumber) async {
    var params = {'pageSize': pageSize, 'pageNumber': pageNumber};
    var apiResult = (await NotesApi.myLatest(params)).data;
    return _getPagedNotesResult(apiResult);
  }

  // fetch tag notes (mine or all)
  Future<NotesResult> tagNotes(String tag, int pageSize, int pageNumber, bool myNotesOnly) async {
    var params = {'tag': tag, 'pageSize': pageSize, 'pageNumber': pageNumber};
    var apiResult = myNotesOnly ? (await NotesApi.myTagNotes(params)).data : (await NotesApi.tagNotes(params)).data;
    return _getPagedNotesResult(apiResult);
  }

  // fetch my latest notes (include private ones)
  Future<NotesResult> memories() async {
    var params = {'localTimeZone': AppConfig.timezone};
    var apiResult = (await NotesApi.memories(params)).data;
    return _getNotesResult(apiResult);
  }

  // fetch my latest notes (include private ones)
  Future<NotesResult> memoriesOn(String yyyyMMdd) async {
    var params = {'localTimeZone': AppConfig.timezone, 'yyyyMMdd': yyyyMMdd};
    var apiResult = (await NotesApi.memoriesOn(params)).data;
    return _getNotesResult(apiResult);
  }

  Future<NotesResult> _getNotesResult(apiResult) async {
    if (!apiResult['successful']) throw ApiException(apiResult);
    List<dynamic> fetchedNotesData = apiResult['data'];
    List<Note> fetchedNotes = _convertNotes(fetchedNotesData);
    return NotesResult(fetchedNotes, fetchedNotes.length);
  }

  Future<NotesResult> _getPagedNotesResult(apiResult) async {
    if (!apiResult['successful']) throw ApiException(apiResult);
    var notes = apiResult['data'];
    int totalNotes = notes['totalCount'];
    List<Note> fetchedNotes = _convertNotes(notes['dataList']);
    return NotesResult(fetchedNotes, totalNotes);
  }

  // List<dynamic> => List<note>
  List<Note> _convertNotes(List<dynamic> fetchedNotesData) {
    return fetchedNotesData.map((json) => Note.fromJson(json)).toList();
  }

  // post a note and get its noteId
  Future<int> post(String content, bool isPrivate, bool isMarkdown) async {
    var params = {
      'content': content,
      'isPrivate': isPrivate,
      'isMarkdown': isMarkdown,
    };
    var apiResult = (await NotesApi.post(params)).data;
    if (!apiResult['successful'] && apiResult['errorCode'] != AppConfig.quietErrorCode) throw ApiException(apiResult);
    return apiResult['data']; //note id
  }

  // update a note and get its noteId
  Future<int> update(int noteId, String content, bool isPrivate, bool isMarkdown) async {
    var params = {
      'id': noteId,
      'content': content,
      'isPrivate': isPrivate,
      'isMarkdown': isMarkdown,
    };
    var apiResult = (await NotesApi.update(params)).data;
    if (!apiResult['successful'] && apiResult['errorCode'] != AppConfig.quietErrorCode) throw ApiException(apiResult);
    return apiResult['data']; //note id
  }

  Future<int> delete(int noteId) async {
    var apiResult = (await NotesApi.delete(noteId)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return apiResult['data']; //note id
  }

  Future<int> undelete(int noteId) async {
    var apiResult = (await NotesApi.undelete(noteId)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return apiResult['data']; //note id
  }

  Future<Note> get(int noteId) async {
    var apiResult = (await NotesApi.get(noteId)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return Note.fromJson(apiResult['data']); //note id
  }
}
