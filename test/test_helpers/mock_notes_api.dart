// Dart
import 'package:happy_notes/apis/notes_api.dart';

class MockNotesApi extends NotesApi {
  // Remove @override annotations since these are static methods in the base class
  static Future<dynamic> myLatest() async => [];
  static Future<dynamic> latest() async => [];
  static Future<dynamic> latestDeleted() async => [];
  static Future<dynamic> getNoteById(String id) async => {};
  static Future<dynamic> createNote(Map<String, dynamic> data) async => {};
  static Future<dynamic> updateNote(String id, Map<String, dynamic> data) async => {};
  static Future<dynamic> deleteNote(String id) async => {};
}
