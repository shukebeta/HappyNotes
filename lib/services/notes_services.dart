import 'package:happy_notes/apis/notes_api.dart';
import '../app_config.dart';
import '../entities/note.dart';
import '../results/notes_result.dart';
import '../utils/util.dart';

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

  // fetch my latest notes (include private ones)
  Future<NotesResult> memories({String localTimeZone='Pacific/Auckland'}) async {
    var params = {'localTimeZone': localTimeZone};
    var apiResult = (await NotesApi.memories(params)).data;
    return _getNotesResult(apiResult);
  }

  // fetch my latest notes (include private ones)
  Future<NotesResult> memoriesOn(String yyyyMMdd, {String localTimeZone='Pacific/Auckland'}) async {
    var params = {'localTimeZone': localTimeZone, 'yyyyMMdd': yyyyMMdd};
    var apiResult = (await NotesApi.memoriesOn(params)).data;
    return _getNotesResult(apiResult);
  }

  Future<NotesResult> _getNotesResult(apiResult) async {
    var currentTimeZone = 'Pacific/Auckland';
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    List<dynamic> fetchedNotesData = apiResult['data'];
    List<Note> fetchedNotes = _convertNotes(fetchedNotesData, currentTimeZone);
    return NotesResult(fetchedNotes, fetchedNotes.length);
  }

  // List<dynamic> => List<note>
  List<Note> _convertNotes(List<dynamic> fetchedNotesData, String currentTimeZone) {
    List<Note> fetchedNotes = fetchedNotesData.map((json) => Note.fromJson(json)).toList();
    fetchedNotes = fetchedNotes.map((el) {
      el.createDate = Util.formatUnixTimestampToLocalDate(el.createAt, 'yyyy-MM-dd', currentTimeZone);
      el.createTime = Util.formatUnixTimestampToLocalDate(el.createAt, 'HH:mm', currentTimeZone);
      return el;
    }).toList();
    return fetchedNotes;
  }

  Future<NotesResult> _getPagedNotesResult(apiResult) async {
    var currentTimeZone = 'Pacific/Auckland';
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    var notes = apiResult['data'];
    int totalNotes = notes['totalCount'];
    List<Note> fetchedNotes = _convertNotes(notes['dataList'], currentTimeZone);
    return NotesResult(fetchedNotes, totalNotes);
  }

  // post a note and get its noteId
  Future<int> post(String content, bool isPrivate) async {
    var params = {'content': content, 'isPrivate': isPrivate};
    var apiResult = (await NotesApi.post(params)).data;
    if (!apiResult['successful'] && apiResult['errorCode'] != AppConfig.errorCodeQuiet) throw Exception(apiResult['message']);
    return apiResult['data']; //note id
  }

  // update a note and get its noteId
  Future<int> update(int noteId, String content, bool isPrivate) async {
    var params = {'id': noteId, 'content': content, 'isPrivate': isPrivate};
    var apiResult = (await NotesApi.update(params)).data;
    if (!apiResult['successful'] && apiResult['errorCode'] != AppConfig.errorCodeQuiet) throw Exception(apiResult['message']);
    return apiResult['data']; //note id
  }

  Future<int> delete(int noteId) async {
    var apiResult = (await NotesApi.delete(noteId)).data;
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    return apiResult['data']; //note id
  }

  Future<int> undelete(int noteId) async {
    var apiResult = (await NotesApi.undelete(noteId)).data;
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    return apiResult['data']; //note id
  }

  Future<Note> get(int noteId) async {
    var apiResult = (await NotesApi.get(noteId)).data;
    if (!apiResult['successful']) throw Exception(apiResult['message']);
    return Note.fromJson(apiResult['data']); //note id
  }
}

