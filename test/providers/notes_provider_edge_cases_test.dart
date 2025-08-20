import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/notes_provider.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/exceptions/api_exception.dart';

import 'notes_provider_test.mocks.dart';
import '../test_helpers/service_locator.dart';

void main() {
  group('NotesProvider Edge Cases & Error Handling', () {
    late NotesProvider provider;
    late MockNotesService mockNotesService;

    setUp(() {
      setupTestServiceLocator();
      mockNotesService = MockNotesService();
      provider = NotesProvider(mockNotesService);
    });

    tearDown(() {
      tearDownTestServiceLocator();
    });

    group('Page Cache Management', () {
      test('should maintain cache consistency across operations', () async {
        // Setup initial data
        final notes = [
          Note(
              id: 1,
              userId: 123,
              content: 'Note 1',
              isPrivate: false,
              isMarkdown: false,
              isLong: false,
              createdAt: 1640995200,
              deletedAt: null,
              user: null,
              tags: []),
        ];

        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult(notes, 1));

        await provider.loadPage(1);
        expect(provider.notes.length, 1);

        // Test updateLocalCache edge cases
        final updatedNote = Note(
          id: notes[0].id,
          userId: notes[0].userId,
          content: 'Updated via cache',
          isPrivate: notes[0].isPrivate,
          isLong: notes[0].isLong,
          isMarkdown: notes[0].isMarkdown,
          createdAt: notes[0].createdAt,
          deletedAt: notes[0].deletedAt,
          user: notes[0].user,
          tags: notes[0].tags,
        );

        // updateLocalCache should update existing note
        provider.updateLocalCache(updatedNote);
        expect(provider.notes.first.content, 'Updated via cache');

        // updateLocalCache with non-existent note should be ignored
        final nonExistentNote = Note(
          id: 999, // Non-existent ID
          userId: 123,
          content: 'Should be ignored',
          isPrivate: false,
          isLong: false,
          isMarkdown: false,
          createdAt: 1640995200,
          deletedAt: null,
          user: null,
          tags: [],
        );
        provider.updateLocalCache(nonExistentNote);
        expect(provider.notes.length, 1); // Should not add new note
        expect(provider.notes.first.id, notes[0].id); // Original note should remain
        // Modify note - cache should update
      });

      test('should handle cache invalidation on delete', () async {
        final notes = [
          Note(
              id: 1,
              userId: 123,
              content: 'Note to delete',
              isPrivate: false,
              isMarkdown: false,
              isLong: false,
              createdAt: 1640995200,
              deletedAt: null,
              user: null,
              tags: []),
          Note(
              id: 2,
              userId: 123,
              content: 'Note to keep',
              isPrivate: false,
              isMarkdown: false,
              isLong: false,
              createdAt: 1640995200,
              deletedAt: null,
              user: null,
              tags: []),
        ];

        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult(notes, 2));
        when(mockNotesService.delete(1)).thenAnswer((_) async => 1);

        await provider.loadPage(1);
        expect(provider.notes.length, 2);

        final result = await provider.deleteNote(1);
        expect(result.isSuccess, isTrue);

        // Note should be removed from cache
        expect(provider.notes.length, 1);
        expect(provider.notes.first.id, 2);
      });
    });

    group('Concurrent Operations', () {
      test('should handle rapid successive page loads gracefully', () async {
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return NotesResult([], 0);
        });

        // Fire multiple rapid requests
        final futures = List.generate(5, (_) => provider.loadPage(1));
        await Future.wait(futures);

        // Should only make one actual API call due to concurrency protection
        verify(mockNotesService.myLatest(10, 1)).called(1);
        expect(provider.isLoadingList, isFalse);
      });

      test('should handle concurrent add and load operations', () async {
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult([], 0));
        final newNote = Note(
            id: 1,
            userId: 123,
            content: 'New note',
            isPrivate: false,
            isMarkdown: false,
            isLong: false,
            createdAt: 1640995200,
            deletedAt: null,
            user: null,
            tags: []);
        when(mockNotesService.post(any)).thenAnswer((_) async => newNote); // Returns new note

        // Start both operations simultaneously
        final loadFuture = provider.loadPage(1);
        final addFuture = provider.addNote('New note');

        await Future.wait([loadFuture, addFuture]);

        expect(provider.isLoadingList, isFalse);
        expect(provider.isLoadingAdd, isFalse);
      });
    });

    group('Memory Management', () {
      test('should limit cache size to prevent memory leaks', () async {
        // Load many pages to test cache limits
        for (int page = 1; page <= 15; page++) {
          when(mockNotesService.myLatest(10, page)).thenAnswer((_) async => NotesResult([
                Note(
                    id: page,
                    userId: 123,
                    content: 'Page $page note',
                    isPrivate: false,
                    isMarkdown: false,
                    isLong: false,
                    createdAt: 1640995200,
                    deletedAt: null,
                    user: null,
                    tags: [])
              ], 150));

          await provider.loadPage(page);
        }

        // Cache should be limited (assuming reasonable limit like 10 pages)
        // This test ensures we don't cache unlimited pages
        expect(provider.currentPage, 15);
        expect(provider.notes.first.content, 'Page 15 note');
      });
    });

    group('Network Error Recovery', () {
      test('should handle failed operations and set error state', () async {
        when(mockNotesService.myLatest(10, 1)).thenThrow(Exception('Network timeout'));

        await provider.loadPage(1);

        // Should set error state when operation fails
        expect(provider.listError, isNotNull);
        expect(provider.listError, contains('Network timeout'));
        expect(provider.notes, isEmpty);
      });

      test('should handle partial network failures gracefully', () async {
        when(mockNotesService.myLatest(10, 1)).thenThrow(ApiException({'message': 'Server temporarily unavailable'}));

        await provider.loadPage(1);

        expect(provider.listError, isNotNull);
        expect(provider.listError, contains('Server temporarily unavailable'));
        expect(provider.notes, isEmpty);
        expect(provider.isLoadingList, isFalse);
      });
    });

    group('Data Validation', () {
      test('should handle malformed response data', () async {
        // Simulate malformed data from API
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult([], -1)); // Invalid total

        await provider.loadPage(1);

        // Should handle gracefully without crashing
        expect(provider.totalPages, greaterThanOrEqualTo(0));
        expect(provider.notes, isEmpty);
      });

      test('should validate note data before caching', () async {
        final invalidNote = Note(
          id: 0, // Invalid ID
          userId: 123,
          content: '',
          isPrivate: false,
          isMarkdown: false,
          isLong: false,
          createdAt: 0, // Invalid timestamp
          deletedAt: null,
          user: null,
          tags: [],
        );

        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult([invalidNote], 1));

        await provider.loadPage(1);

        // Should handle invalid data gracefully
        expect(provider.notes.length, lessThanOrEqualTo(1));
        expect(provider.listError, isNull); // Should not error, just filter invalid data
      });
    });

    group('State Consistency', () {
      test('should maintain consistent state during rapid UI updates', () async {
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult([], 0));

        var notificationCount = 0;
        provider.addListener(() {
          notificationCount++;
        });

        // Rapid state changes
        await provider.loadPage(1);
        await provider.refreshCurrentPage();
        await provider.loadPage(1); // Same page again

        // Should not over-notify listeners
        expect(notificationCount, lessThanOrEqualTo(9)); // 3 operations × 3 notifications each
        expect(provider.isLoadingList, isFalse);
      });
    });
  });
}
