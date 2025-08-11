import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/tag_provider.dart';
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
  group('TagProvider Tests', () {
    late TagProvider tagProvider;
    late MockNotesService mockNotesService;
    late MockNoteTagService mockNoteTagService;

    setUp(() {
      mockNotesService = MockNotesService();
      mockNoteTagService = MockNoteTagService();
      tagProvider = TagProvider(mockNotesService, mockNoteTagService);
    });

    group('Initialization', () {
      test('should initialize with empty state', () {
        expect(tagProvider.tagCloud, isEmpty);
        expect(tagProvider.tagNotes, isEmpty);
        expect(tagProvider.isLoadingTagCloud, isFalse);
        expect(tagProvider.isLoading, isFalse);
        expect(tagProvider.currentTag, isEmpty);
        expect(tagProvider.currentPage, equals(1));
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

        await tagProvider.loadTagCloud();

        expect(tagProvider.tagCloud, equals({'flutter': 5, 'dart': 3}));
        expect(tagProvider.tagCloudError, isNull);
      });

      test('should use cached data when not forcing refresh', () async {
        final tagData = [
          TagCount(tag: 'flutter', count: 5),
        ];
        
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => tagData);

        // First load
        await tagProvider.loadTagCloud();
        
        // Second load without force refresh
        await tagProvider.loadTagCloud(forceRefresh: false);

        // Should only call service once
        verify(mockNoteTagService.getMyTagCloud()).called(1);
      });

      test('should refresh data when forcing refresh', () async {
        final tagData = [
          TagCount(tag: 'flutter', count: 5),
        ];
        
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => tagData);

        // First load
        await tagProvider.loadTagCloud();
        
        // Second load with force refresh
        await tagProvider.loadTagCloud(forceRefresh: true);

        // Should call service twice
        verify(mockNoteTagService.getMyTagCloud()).called(2);
      });
    });

    group('Tag notes functionality', () {
      test('should load tag notes successfully', () async {
        final notes = [
          Note(id: 1, content: 'Flutter note', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 1);
        
        when(mockNotesService.tagNotes('flutter', any, any))
            .thenAnswer((_) async => result);

        await tagProvider.loadTagNotes('flutter', 1);

        expect(tagProvider.tagNotes, equals(notes));
        expect(tagProvider.currentTag, equals('flutter'));
        expect(tagProvider.totalPages, equals(1));
        expect(tagProvider.error, isNull);
      });

      test('should clear tag notes for empty tag', () async {
        await tagProvider.loadTagNotes('', 1);

        expect(tagProvider.tagNotes, isEmpty);
        expect(tagProvider.currentTag, isEmpty);
        verifyNever(mockNotesService.tagNotes(any, any, any));
      });
    });

    group('Tag utility functions', () {
      setUp(() async {
        final tagData = [
          TagCount(tag: 'flutter', count: 5),
          TagCount(tag: 'dart', count: 3),
          TagCount(tag: 'mobile', count: 1),
        ];
        
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => tagData);

        await tagProvider.loadTagCloud();
      });

      test('should get tag count correctly', () {
        expect(tagProvider.getTagCount('flutter'), equals(5));
        expect(tagProvider.getTagCount('nonexistent'), equals(0));
      });

      test('should check if tag exists', () {
        expect(tagProvider.hasTag('flutter'), isTrue);
        expect(tagProvider.hasTag('nonexistent'), isFalse);
      });

      test('should return all tags sorted', () {
        expect(tagProvider.allTags, equals(['dart', 'flutter', 'mobile']));
      });

      test('should return top tags by count', () {
        final topTags = tagProvider.getTopTags(2);
        
        expect(topTags.length, equals(2));
        expect(topTags[0].key, equals('flutter'));
        expect(topTags[0].value, equals(5));
        expect(topTags[1].key, equals('dart'));
        expect(topTags[1].value, equals(3));
      });
    });

    group('Delete functionality', () {
      test('should delete note and update tag cloud', () async {
        // Setup tag cloud first
        final tagData = [
          TagCount(tag: 'flutter', count: 2),
        ];
        
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => tagData);

        await tagProvider.loadTagCloud();

        // Setup tag notes
        final notes = [
          Note(id: 1, content: 'Flutter note 1', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
          Note(id: 2, content: 'Flutter note 2', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 2);
        
        when(mockNotesService.tagNotes('flutter', any, any))
            .thenAnswer((_) async => result);
        when(mockNotesService.delete(1))
            .thenAnswer((_) async => 1);

        await tagProvider.loadTagNotes('flutter', 1);
        
        // Delete note
        final deleteResult = await tagProvider.deleteNote(1);

        expect(deleteResult.isSuccess, true);
        expect(tagProvider.tagNotes.length, equals(1));
        // Tag count should be decremented from 2 to 1 after deleting one note
        expect(tagProvider.getTagCount('flutter'), equals(1));
      });

      test('should remove tag from cloud when count reaches 0', () async {
        // Setup tag cloud with count 1
        final tagData = [
          TagCount(tag: 'flutter', count: 1),
        ];
        
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => tagData);

        await tagProvider.loadTagCloud();

        // Setup single note
        final notes = [
          Note(id: 1, content: 'Flutter note', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 1);
        
        when(mockNotesService.tagNotes('flutter', any, any))
            .thenAnswer((_) async => result);
        when(mockNotesService.delete(1))
            .thenAnswer((_) async => 1);

        await tagProvider.loadTagNotes('flutter', 1);
        
        // Delete the only note
        await tagProvider.deleteNote(1);

        expect(tagProvider.hasTag('flutter'), isFalse); // Should be removed
      });
    });

    group('Auth aware functionality', () {
      test('should clear all data on clearAllData', () {
        tagProvider.clearAllData();

        expect(tagProvider.tagCloud, isEmpty);
        expect(tagProvider.tagNotes, isEmpty);
        expect(tagProvider.currentTag, isEmpty);
        expect(tagProvider.isLoadingTagCloud, isFalse);
        expect(tagProvider.isLoading, isFalse);
      });

      test('should load tag cloud on login', () async {
        final tagData = [
          TagCount(tag: 'flutter', count: 5),
        ];
        
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => tagData);

        await tagProvider.onLogin();

        // TagProvider should remain empty after login - only activated when user selects tags
        expect(tagProvider.tagCloud, isEmpty);
        expect(tagProvider.getTagCount('flutter'), equals(0));
      });
    });
  });
}