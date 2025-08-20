import 'package:happy_notes/apis/notes_api.dart';
import 'package:happy_notes/models/note_model.dart';
import 'package:intl/intl.dart';
import '../app_config.dart';
import '../entities/note.dart';
import '../exceptions/api_exception.dart';
import '../models/notes_result.dart';
import 'seq_logger.dart';

class NotesService {
  /// Validate API response structure and log contract violations
  void _validateApiResponse(dynamic apiResult, String operation) {
    if (apiResult == null) {
      SeqLogger.severe('API contract violation: $operation returned null response');
      throw ApiException({'successful': false, 'message': 'Null API response'});
    }

    if (apiResult is! Map) {
      SeqLogger.severe('API contract violation: $operation returned non-Map response: ${apiResult.runtimeType}');
      throw ApiException({'successful': false, 'message': 'Invalid API response format'});
    }

    if (!apiResult.containsKey('successful')) {
      SeqLogger.severe('API contract violation: $operation missing "successful" field');
      throw ApiException({'successful': false, 'message': 'Malformed API response'});
    }
  }

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
  Future<NotesResult> searchNotes(String query, int pageSize, int pageNumber) async {
    var apiResult = (await NotesApi.searchNotes(query, pageSize, pageNumber)).data;
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
    if (!apiResult['successful'] && apiResult['errorCode'] != AppConfig.quietErrorCode) {
      throw ApiException(apiResult);
    }
    return Note.fromJson(apiResult['data']); //complete note object
  }

  // update a note and get the updated note
  Future<Note> update(int noteId, String content, bool isPrivate, bool isMarkdown) async {
    SeqLogger.info(
        'NotesService.update called: noteId=$noteId, content length=${content.length}, isPrivate=$isPrivate, isMarkdown=$isMarkdown');

    var params = {
      'id': noteId,
      'content': content,
      'isPrivate': isPrivate,
      'isMarkdown': isMarkdown,
    };

    SeqLogger.info('NotesService.update calling NotesApi.update with params: $params');
    var apiResult = (await NotesApi.update(params)).data;

    if (!apiResult['successful'] && apiResult['errorCode'] != AppConfig.quietErrorCode) {
      SeqLogger.severe('NotesService.update API error: ${apiResult['errorMessage']} for noteId=$noteId');
      throw ApiException(apiResult);
    }

    final updatedNote = Note.fromJson(apiResult['data']);
    return updatedNote; //complete note object
  }

  Future<int> delete(int noteId) async {
    var apiResult = (await NotesApi.delete(noteId)).data;
    _validateApiResponse(apiResult, 'delete');
    if (!apiResult['successful']) throw ApiException(apiResult);

    final data = apiResult['data'];
    if (data is! int) {
      SeqLogger.severe('delete API returned non-int data: ${data.runtimeType} = $data');
      throw ApiException({'successful': false, 'message': 'Invalid note ID returned'});
    }
    return data;
  }

  Future<int> undelete(int noteId) async {
    var apiResult = (await NotesApi.undelete(noteId)).data;
    _validateApiResponse(apiResult, 'undelete');
    if (!apiResult['successful']) throw ApiException(apiResult);

    final data = apiResult['data'];
    if (data is! int) {
      SeqLogger.severe('undelete API returned non-int data: ${data.runtimeType} = $data');
      throw ApiException({'successful': false, 'message': 'Invalid note ID returned'});
    }
    return data;
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

  Future<void> purgeDeleted() async {
    var apiResult = (await NotesApi.purgeDeleted()).data;
    _validateApiResponse(apiResult, 'purgeDeleted');

    if (!apiResult['successful']) throw ApiException(apiResult);

    // Log unexpected data for debugging (purgeDeleted should return data: null)
    if (apiResult['data'] != null) {
      SeqLogger.info('purgeDeleted returned data: ${apiResult['data']} (expected: null)');
    }
  }
}
