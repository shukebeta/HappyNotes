import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/search_provider.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/services/note_tag_service.dart';
import 'package:happy_notes/models/tag_count.dart';

import 'notes_provider_test.mocks.dart';

class MockNoteTagService extends Mock implements NoteTagService {
  @override
  Future<List<TagCount>> getMyTagCloud() => super.noSuchMethod(
    Invocation.method(#getMyTagCloud, []),
    returnValue: Future.value(<TagCount>[]),
  );
}

void main() {
  group('SearchProvider Tests', () {
    late SearchProvider searchProvider;
    late MockNotesService mockNotesService;
    late MockNoteTagService mockNoteTagService;

    setUp(() {
      mockNotesService = MockNotesService();
      mockNoteTagService = MockNoteTagService();
      searchProvider = SearchProvider(mockNotesService, mockNoteTagService);
    });

    group('Initialization', () {
      test('should initialize with empty state', () {
        expect(searchProvider.searchResults, isEmpty);
        expect(searchProvider.isLoading, isFalse);
        expect(searchProvider.error, isNull);
        expect(searchProvider.currentQuery, isEmpty);
        expect(searchProvider.currentPage, equals(1));
        expect(searchProvider.totalNotes, equals(1));
        expect(searchProvider.totalPages, equals(1));
      });
    });

    group('Search functionality', () {
      test('should search notes successfully', () async {
        final notes = [
          Note(id: 1, content: 'Test note', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 1);
        
        when(mockNotesService.searchNotes('test', any, any))
            .thenAnswer((_) async => result);

        await searchProvider.searchNotes('test', 1);

        expect(searchProvider.searchResults, equals(notes));
        expect(searchProvider.currentQuery, equals('test'));
        expect(searchProvider.totalNotes, equals(1));
        expect(searchProvider.error, isNull);
      });

      test('should clear search results for empty query', () async {
        await searchProvider.searchNotes('', 1);

        expect(searchProvider.searchResults, isEmpty);
        expect(searchProvider.currentQuery, isEmpty);
        verifyNever(mockNotesService.searchNotes(any, any, any));
      });

      test('should handle search errors', () async {
        when(mockNotesService.searchNotes(any, any, any))
            .thenThrow(Exception('Search failed'));

        await searchProvider.searchNotes('test', 1);

        expect(searchProvider.searchResults, isEmpty);
        expect(searchProvider.error, contains('Search failed'));
      });
    });

    group('Tag cloud functionality', () {
      test('should load tag cloud successfully', () async {
        final tagData = [
          TagCount(tag: 'flutter', count: 5),
          TagCount(tag: 'dart', count: 3),
        ];
        
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => tagData);

        await searchProvider.loadTagCloud();

        expect(searchProvider.tagCloud, equals({'flutter': 5, 'dart': 3}));
        expect(searchProvider.tagCloudError, isNull);
      });
    });

    group('Delete functionality', () {
      test('should delete note successfully', () async {
        // Setup initial search results
        final notes = [
          Note(id: 1, content: 'Test note 1', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
          Note(id: 2, content: 'Test note 2', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 2);
        
        when(mockNotesService.searchNotes('test', any, any))
            .thenAnswer((_) async => result);
        when(mockNotesService.delete(1))
            .thenAnswer((_) async => 1);

        // Search first to populate results
        await searchProvider.searchNotes('test', 1);
        
        // Delete note
        final deleteResult = await searchProvider.deleteNote(1);

        expect(deleteResult, isTrue);
        expect(searchProvider.searchResults.length, equals(1));
        expect(searchProvider.searchResults.first.id, equals(2));
        expect(searchProvider.totalNotes, equals(1));
      });

      test('should handle delete errors', () async {
        when(mockNotesService.delete(any))
            .thenThrow(Exception('Delete failed'));

        final deleteResult = await searchProvider.deleteNote(1);

        expect(deleteResult, isFalse);
        expect(searchProvider.error, contains('Delete failed'));
      });
    });

    group('Auth aware functionality', () {
      test('should clear all data on clearAllData', () {
        searchProvider.clearAllData();

        expect(searchProvider.searchResults, isEmpty);
        expect(searchProvider.tagCloud, isEmpty);
        expect(searchProvider.isLoading, isFalse);
        expect(searchProvider.error, isNull);
        expect(searchProvider.currentQuery, isEmpty);
      });

      test('should load tag cloud on login', () async {
        final tagData = [
          TagCount(tag: 'flutter', count: 5),
        ];
        
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => tagData);

        await searchProvider.onLogin();

        expect(searchProvider.tagCloud, equals({'flutter': 5}));
      });
    });
  });
}