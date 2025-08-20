import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/models/notes_result.dart';

class MockNotesService extends NotesService {
  @override
  Future<NotesResult> myLatest(int pageSize, int pageNumber) async => NotesResult([], 0);
  @override
  Future<NotesResult> latest(int pageSize, int pageNumber) async => NotesResult([], 0);
  @override
  Future<NotesResult> latestDeleted(int pageSize, int pageNumber) async => NotesResult([], 0);
  Future<dynamic> getNoteById(int id) async => {};
  Future<int> createNote(Map<String, dynamic> data) async => 1;
  Future<int> updateNote(int id, Map<String, dynamic> data) async => 1;
  Future<int> deleteNote(int id) async => 1;
}
