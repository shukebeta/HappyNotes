import 'package:HappyNotes/apis/notes_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotesService {
  static Future<dynamic> latest(int pageSize, int pageNumber) async {
    var params = {'pageSize': pageSize, 'pageNumber': pageNumber};
    return (await NotesApi.latest(params)).data;
  }

  static Future<dynamic> myLatest(int pageSize, int pageNumber) async {
    var params = {'pageSize': pageSize, 'pageNumber': pageNumber};
    return (await NotesApi.myLatest(params)).data;
  }

  static Future<dynamic> post(String content) async {
    var params = {'content': content};
    return (await NotesApi.post(params)).data;
  }

  static Future<dynamic> update(int noteId, String content) async {
    var params = {'id': noteId, 'content': content};
    return (await NotesApi.update(params)).data;
  }
}
