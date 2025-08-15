import 'package:happy_notes/apis/notes_api.dart';
import 'package:happy_notes/models/note_model.dart';
import 'package:intl/intl.dart';
import '../app_config.dart';
import '../entities/note.dart';
import '../exceptions/api_exception.dart';
import '../models/notes_result.dart';
import '../utils/app_logger_interface.dart';
import 'package:get_it/get_it.dart';

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
  Future<NotesResult> tagNotes(String tag, int pageSize, int pageNumber) async {
    var params = {'tag': tag, 'pageSize': pageSize, 'pageNumber': pageNumber};
    var apiResult = (await NotesApi.tagNotes(params)).data;
    return _getPagedNotesResult(apiResult);
  }

// Search notes by keyword
  Future<NotesResult> searchNotes(
      String query, int pageSize, int pageNumber) async {
    var apiResult =
        (await NotesApi.searchNotes(query, pageSize, pageNumber)).data;
    // Reuse the existing helper to parse the paged result structure
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

  // fetch my latest notes (include private ones)
  Future<NotesResult> getLinkedNotes(int noteId) async {
    var apiResult = (await NotesApi.getLinkedNotes(noteId)).data;
    return _getPagedNotesResult(apiResult);
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
    int totalNotes = notes['totalCount'] ?? 0;
    List<Note> fetchedNotes = _convertNotes(notes['dataList'] ?? []);
    return NotesResult(fetchedNotes, totalNotes);
  }

  // List<dynamic> => List<note>
  List<Note> _convertNotes(List<dynamic> fetchedNotesData) {
    return fetchedNotesData.map((json) => Note.fromJson(json)).toList();
  }

  // post a note and get the created note
  Future<Note> post(NoteModel noteModel) async {
    var now = DateTime.now();
    var params = {
      'content': noteModel.content,
      'isPrivate': noteModel.isPrivate,
      'isMarkdown': noteModel.isMarkdown,
      'publishDateTime': noteModel.publishDateTime.isEmpty
          ? ''
          : DateFormat('yyyy-MM-dd HH:mm:ss').format(
              DateTime.parse(noteModel.publishDateTime).add(Duration(
                hours: now.hour,
                minutes: now.minute,
                seconds: now.second,
              )),
            ),
      'timezoneId': AppConfig.timezone,
    };
    var apiResult = (await NotesApi.post(params)).data;
    if (!apiResult['successful'] &&
        apiResult['errorCode'] != AppConfig.quietErrorCode) {
      throw ApiException(apiResult);
    }
    return Note.fromJson(apiResult['data']); //complete note object
  }

  // update a note and get the updated note
  Future<Note> update(
      int noteId, String content, bool isPrivate, bool isMarkdown) async {
    final logger = GetIt.instance<AppLoggerInterface>();
    
    logger.d('NotesService.update called: noteId=$noteId, content length=${content.length}, isPrivate=$isPrivate, isMarkdown=$isMarkdown');
    
    var params = {
      'id': noteId,
      'content': content,
      'isPrivate': isPrivate,
      'isMarkdown': isMarkdown,
    };
    
    logger.d('NotesService.update calling NotesApi.update with params: $params');
    var apiResult = (await NotesApi.update(params)).data;
    
    if (!apiResult['successful'] &&
        apiResult['errorCode'] != AppConfig.quietErrorCode) {
      logger.e('NotesService.update API error: ${apiResult['errorMessage']} for noteId=$noteId');
      throw ApiException(apiResult);
    }
    
    final updatedNote = Note.fromJson(apiResult['data']);
    return updatedNote; //complete note object
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
    return Note.fromJson(apiResult['data']);
  }

  Future<NotesResult> latestDeleted(int pageSize, int pageNumber) async {
    var apiResult = (await NotesApi.latestDeleted(pageSize, pageNumber)).data;
    return _getPagedNotesResult(apiResult);
  }

  Future<int> purgeDeleted() async {
    var apiResult = (await NotesApi.purgeDeleted()).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return apiResult['data'];
  }
}
