import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/tag_notes_provider.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';

import 'notes_provider_test.mocks.dart';

void main() {
  group('TagNotesProvider Tests', () {
    late TagNotesProvider tagNotesProvider;
    late MockNotesService mockNotesService;

    setUp(() {
      mockNotesService = MockNotesService();
      tagNotesProvider = TagNotesProvider(mockNotesService);
    });

    group('Initialization', () {
      test('should initialize with correct default values', () {
        expect(tagNotesProvider.notes, isEmpty);
        expect(tagNotesProvider.tagNotes, isEmpty); // Alias
        expect(tagNotesProvider.currentTag, isEmpty);
        expect(tagNotesProvider.currentPage, equals(1));
        expect(tagNotesProvider.totalPages, equals(1));
        expect(tagNotesProvider.isLoading, isFalse);
        expect(tagNotesProvider.error, isNull);
        expect(tagNotesProvider.groupedNotes, isEmpty);
      });

      test('should extend NoteListProvider', () {
        // Verify inheritance of core functionality
        expect(tagNotesProvider.notes, isA<List<Note>>());
        expect(tagNotesProvider.currentPage, isA<int>());
        expect(tagNotesProvider.totalPages, isA<int>());
        expect(tagNotesProvider.isLoading, isA<bool>());
        expect(tagNotesProvider.error, anyOf(isNull, isA<String>()));
        expect(tagNotesProvider.groupedNotes, isA<Map<String, List<Note>>>());
      });
    });

    group('Tag state management', () {
      test('should load tag notes and set current tag', () async {
        final taggedNotes = [
          Note(id: 1, content: 'Flutter note', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['flutter']),
          Note(id: 2, content: 'Dart note', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['flutter']),
        ];
        final result = NotesResult(taggedNotes, 2);

        when(mockNotesService.tagNotes('flutter', 10, 1))
            .thenAnswer((_) async => result);

        await tagNotesProvider.loadTagNotes('flutter', 1);

        // Verify tag state is set
        expect(tagNotesProvider.currentTag, equals('flutter'));

        // Verify correct service method was called
        verify(mockNotesService.tagNotes('flutter', 10, 1)).called(1);
        verifyNever(mockNotesService.latest(any, any)); // Should NOT call latest
        verifyNever(mockNotesService.myLatest(any, any)); // Should NOT call myLatest

        // Verify results
        expect(tagNotesProvider.notes, equals(taggedNotes));
        expect(tagNotesProvider.tagNotes, equals(taggedNotes)); // Alias should work
        expect(tagNotesProvider.currentPage, equals(1));
        expect(tagNotesProvider.error, isNull);
      });

      test('should clear tag notes and reset current tag', () async {
        // First load some tag notes
        when(mockNotesService.tagNotes('flutter', 10, 1))
            .thenAnswer((_) async => NotesResult([
              Note(id: 1, content: 'Test note', isPrivate: false, userId: 1,
                   isLong: false, isMarkdown: false, createdAt: 1640995200,
                   deletedAt: null, user: null, tags: ['flutter']),
            ], 1));

        await tagNotesProvider.loadTagNotes('flutter', 1);
        expect(tagNotesProvider.currentTag, equals('flutter'));
        expect(tagNotesProvider.notes.isNotEmpty, isTrue);

        // Clear tag notes
        tagNotesProvider.clearTagNotes();

        expect(tagNotesProvider.currentTag, isEmpty);
        expect(tagNotesProvider.notes, isEmpty);
        expect(tagNotesProvider.currentPage, equals(1));
        expect(tagNotesProvider.totalPages, equals(1));
        expect(tagNotesProvider.error, isNull);
      });

      test('should handle empty tag input by clearing data', () async {
        // First set up some tag data
        when(mockNotesService.tagNotes('flutter', 10, 1))
            .thenAnswer((_) async => NotesResult([
              Note(id: 1, content: 'Test note', isPrivate: false, userId: 1,
                   isLong: false, isMarkdown: false, createdAt: 1640995200,
                   deletedAt: null, user: null, tags: ['flutter']),
            ], 1));

        await tagNotesProvider.loadTagNotes('flutter', 1);
        expect(tagNotesProvider.currentTag, equals('flutter'));

        // Load with empty tag should clear data
        await tagNotesProvider.loadTagNotes('', 1);

        expect(tagNotesProvider.currentTag, isEmpty);
        expect(tagNotesProvider.notes, isEmpty);

        // Should not call service for empty tag
        verifyNever(mockNotesService.tagNotes('', any, any));
      });

      test('should handle whitespace-only tag input by clearing data', () async {
        // First set up some tag data
        when(mockNotesService.tagNotes('flutter', 10, 1))
            .thenAnswer((_) async => NotesResult([
              Note(id: 1, content: 'Test note', isPrivate: false, userId: 1,
                   isLong: false, isMarkdown: false, createdAt: 1640995200,
                   deletedAt: null, user: null, tags: ['flutter']),
            ], 1));

        await tagNotesProvider.loadTagNotes('flutter', 1);
        expect(tagNotesProvider.currentTag, equals('flutter'));

        // Load with whitespace-only tag should clear data
        await tagNotesProvider.loadTagNotes('   ', 1);

        expect(tagNotesProvider.currentTag, isEmpty);
        expect(tagNotesProvider.notes, isEmpty);

        // Should not call service for whitespace tag
        verifyNever(mockNotesService.tagNotes('   ', any, any));
      });

      test('should switch between different tags correctly', () async {
        final flutterNotes = [
          Note(id: 1, content: 'Flutter note', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['flutter']),
        ];
        final dartNotes = [
          Note(id: 2, content: 'Dart note', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['dart']),
        ];

        // Load flutter notes first
        when(mockNotesService.tagNotes('flutter', 10, 1))
            .thenAnswer((_) async => NotesResult(flutterNotes, 1));
        await tagNotesProvider.loadTagNotes('flutter', 1);

        expect(tagNotesProvider.currentTag, equals('flutter'));
        expect(tagNotesProvider.notes, equals(flutterNotes));

        // Switch to dart notes
        when(mockNotesService.tagNotes('dart', 10, 1))
            .thenAnswer((_) async => NotesResult(dartNotes, 1));
        await tagNotesProvider.loadTagNotes('dart', 1);

        expect(tagNotesProvider.currentTag, equals('dart'));
        expect(tagNotesProvider.notes, equals(dartNotes));

        // Verify both service calls were made
        verify(mockNotesService.tagNotes('flutter', 10, 1)).called(1);
        verify(mockNotesService.tagNotes('dart', 10, 1)).called(1);
      });
    });

    group('Conditional data loading', () {
      test('should return empty result when no tag is set', () async {
        // Call fetchNotes directly (this is what navigateToPage calls)
        final result = await tagNotesProvider.fetchNotes(10, 1);

        expect(result.notes, isEmpty);
        expect(result.totalNotes, equals(0));

        // Should not call any service method
        verifyZeroInteractions(mockNotesService);
      });

      test('should call tagNotes service when tag is set', () async {
        final taggedNotes = [
          Note(id: 1, content: 'Tagged note', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['test']),
        ];

        when(mockNotesService.tagNotes('test', 10, 1))
            .thenAnswer((_) async => NotesResult(taggedNotes, 1));

        // Set tag first
        await tagNotesProvider.loadTagNotes('test', 1);

        // Verify service was called with correct parameters
        verify(mockNotesService.tagNotes('test', 10, 1)).called(1);
        expect(tagNotesProvider.notes, equals(taggedNotes));
      });

      test('should handle pagination correctly for tagged notes', () async {
        final firstPageNotes = [
          Note(id: 1, content: 'Tagged note 1', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['test']),
        ];
        final secondPageNotes = [
          Note(id: 2, content: 'Tagged note 2', isPrivate: false, userId: 2,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['test']),
        ];

        // Setup first page
        when(mockNotesService.tagNotes('test', 10, 1))
            .thenAnswer((_) async => NotesResult(firstPageNotes, 25)); // Multiple pages
        await tagNotesProvider.loadTagNotes('test', 1);
        expect(tagNotesProvider.totalPages, equals(3)); // ceil(25/10) = 3

        // Setup second page
        when(mockNotesService.tagNotes('test', 10, 2))
            .thenAnswer((_) async => NotesResult(secondPageNotes, 25));
        await tagNotesProvider.loadTagNotes('test', 2);

        // Verify pagination calls
        verify(mockNotesService.tagNotes('test', 10, 1)).called(1);
        verify(mockNotesService.tagNotes('test', 10, 2)).called(1);

        expect(tagNotesProvider.currentPage, equals(2));
        expect(tagNotesProvider.currentTag, equals('test')); // Tag should remain set
        expect(tagNotesProvider.notes, equals(secondPageNotes));
      });

      test('should handle service errors during tag loading', () async {
        when(mockNotesService.tagNotes('error-tag', 10, 1))
            .thenThrow(Exception('Tag service unavailable'));

        await tagNotesProvider.loadTagNotes('error-tag', 1);

        verify(mockNotesService.tagNotes('error-tag', 10, 1)).called(1);
        expect(tagNotesProvider.error, contains('Tag service unavailable'));
        expect(tagNotesProvider.notes, isEmpty);
        expect(tagNotesProvider.currentTag, equals('error-tag')); // Tag should still be set
        expect(tagNotesProvider.isLoading, isFalse);
      });
    });

    group('Refresh functionality', () {
      test('should refresh tag notes when tag is set', () async {
        final initialNotes = [
          Note(id: 1, content: 'Old tagged note', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['refresh-test']),
        ];
        final refreshedNotes = [
          Note(id: 1, content: 'Updated tagged note', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['refresh-test']),
          Note(id: 2, content: 'New tagged note', isPrivate: false, userId: 2,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['refresh-test']),
        ];

        // Setup initial load
        when(mockNotesService.tagNotes('refresh-test', 10, 1))
            .thenAnswer((_) async => NotesResult(initialNotes, 1));
        await tagNotesProvider.loadTagNotes('refresh-test', 1);
        expect(tagNotesProvider.notes.length, equals(1));

        // Setup refresh with updated data
        when(mockNotesService.tagNotes('refresh-test', 10, 1))
            .thenAnswer((_) async => NotesResult(refreshedNotes, 2));
        await tagNotesProvider.refreshTagNotes();

        // Verify refresh calls correct service method
        verify(mockNotesService.tagNotes('refresh-test', 10, 1)).called(2); // Initial + refresh
        expect(tagNotesProvider.notes.length, equals(2));
        expect(tagNotesProvider.notes.first.content, equals('Updated tagged note'));
        expect(tagNotesProvider.currentTag, equals('refresh-test')); // Tag should remain
      });

      test('should not refresh when no tag is set', () async {
        // Try to refresh without setting a tag
        await tagNotesProvider.refreshTagNotes();

        // Should not call any service method
        verifyZeroInteractions(mockNotesService);
        expect(tagNotesProvider.notes, isEmpty);
        expect(tagNotesProvider.currentTag, isEmpty);
      });
    });

    group('Delete functionality', () {
      test('should delete tagged notes using correct service method', () async {
        final testNotes = [
          Note(id: 1, content: 'Tagged note 1', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['delete-test']),
          Note(id: 2, content: 'Tagged note 2', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['delete-test']),
        ];

        // Setup initial state
        when(mockNotesService.tagNotes('delete-test', 10, 1))
            .thenAnswer((_) async => NotesResult(testNotes, 2));
        await tagNotesProvider.loadTagNotes('delete-test', 1);
        expect(tagNotesProvider.notes.length, equals(2));

        // Setup successful delete
        when(mockNotesService.delete(1))
            .thenAnswer((_) async => 1);

        final result = await tagNotesProvider.deleteNote(1);

        // Verify correct delete method was called
        verify(mockNotesService.delete(1)).called(1);

        // Verify optimistic update (inherited from NoteListProvider)
        expect(result.isSuccess, isTrue);
        expect(tagNotesProvider.notes.length, equals(1));
        expect(tagNotesProvider.notes.first.id, equals(2));
        expect(tagNotesProvider.currentTag, equals('delete-test')); // Tag should remain
      });

      test('should handle delete errors with rollback', () async {
        final testNotes = [
          Note(id: 1, content: 'Tagged note', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['delete-error']),
        ];

        // Setup initial state
        when(mockNotesService.tagNotes('delete-error', 10, 1))
            .thenAnswer((_) async => NotesResult(testNotes, 1));
        await tagNotesProvider.loadTagNotes('delete-error', 1);

        // Setup delete failure
        when(mockNotesService.delete(1))
            .thenThrow(Exception('Delete permission denied'));

        final result = await tagNotesProvider.deleteNote(1);

        verify(mockNotesService.delete(1)).called(1);

        // Verify rollback (inherited from NoteListProvider)
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Delete permission denied'));
        expect(tagNotesProvider.notes.length, equals(1)); // Rolled back
        expect(tagNotesProvider.notes.first.id, equals(1)); // Original note restored
        expect(tagNotesProvider.currentTag, equals('delete-error')); // Tag should remain
      });
    });

    group('State management integration', () {
      test('should clear all data including tag state', () async {
        final testNotes = [
          Note(id: 1, content: 'Tagged note', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: null, user: null, tags: ['clear-test']),
        ];

        // Setup some state
        when(mockNotesService.tagNotes('clear-test', 10, 1))
            .thenAnswer((_) async => NotesResult(testNotes, 1));
        await tagNotesProvider.loadTagNotes('clear-test', 1);
        expect(tagNotesProvider.notes.isNotEmpty, isTrue);
        expect(tagNotesProvider.currentTag, equals('clear-test'));

        // Clear all data (inherited from NoteListProvider, extended for tag)
        tagNotesProvider.clearNotesCache();

        expect(tagNotesProvider.notes, isEmpty);
        expect(tagNotesProvider.currentTag, isEmpty); // Tag-specific clearing
        expect(tagNotesProvider.currentPage, equals(1));
        expect(tagNotesProvider.totalPages, equals(1));
        expect(tagNotesProvider.isLoading, isFalse);
        expect(tagNotesProvider.error, isNull);
        expect(tagNotesProvider.groupedNotes, isEmpty);
      });
    });

    group('AuthAwareProvider integration', () {
      test('should inherit authentication-aware functionality', () {
        // Verify inheritance from NoteListProvider -> AuthAwareProvider
        expect(tagNotesProvider.isAuthStateInitialized, isFalse);

        // Should have inherited methods available
        expect(() => tagNotesProvider.clearNotesCache(), returnsNormally);
      });
    });
  });
}
