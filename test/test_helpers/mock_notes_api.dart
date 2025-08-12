// Dart
import 'package:happy_notes/apis/notes_api.dart';

class MockNotesApi extends NotesApi {
  @override
  Future<dynamic> myLatest() async => [];
  @override
  Future<dynamic> latest() async => [];
  @override
  Future<dynamic> latestDeleted() async => [];
  @override
  Future<dynamic> getNoteById(String id) async => {};
  @override
  Future<dynamic> createNote(Map<String, dynamic> data) async => {};
  @override
  Future<dynamic> updateNote(String id, Map<String, dynamic> data) async => {};
  @override
  Future<dynamic> deleteNote(String id) async => {};
}