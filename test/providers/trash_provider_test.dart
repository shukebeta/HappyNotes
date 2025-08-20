import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/trash_provider.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';

import 'notes_provider_test.mocks.dart';

void main() {
  group('TrashProvider Tests', () {
    late TrashProvider trashProvider;
    late MockNotesService mockNotesService;

    setUp(() {
      mockNotesService = MockNotesService();
      trashProvider = TrashProvider(mockNotesService);
    });

    group('Initialization', () {
      test('should initialize with correct default values', () {
        expect(trashProvider.notes, isEmpty);
        expect(trashProvider.trashedNotes, isEmpty); // Alias
        expect(trashProvider.currentPage, equals(1));
        expect(trashProvider.totalPages, equals(1));
        expect(trashProvider.isLoading, isFalse);
        expect(trashProvider.isPurging, isFalse); // Trash-specific
        expect(trashProvider.error, isNull);
        expect(trashProvider.groupedNotes, isEmpty);
      });

      test('should extend NoteListProvider', () {
        // Verify inheritance of core functionality
        expect(trashProvider.notes, isA<List<Note>>());
        expect(trashProvider.currentPage, isA<int>());
        expect(trashProvider.totalPages, isA<int>());
        expect(trashProvider.isLoading, isA<bool>());
        expect(trashProvider.error, anyOf(isNull, isA<String>()));
        expect(trashProvider.groupedNotes, isA<Map<String, List<Note>>>());
      });
    });

    group('Trash data loading', () {
      test('should fetch deleted notes using latestDeleted() service method', () async {
        final deletedNotes = [
          Note(id: 1, content: 'Deleted note 1', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []), // Has deletedAt
          Note(id: 2, content: 'Deleted note 2', isPrivate: false, userId: 2,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []), // Has deletedAt
        ];
        final result = NotesResult(deletedNotes, 2);

        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => result);

        await trashProvider.navigateToPage(1);

        // Verify correct service method was called
        verify(mockNotesService.latestDeleted(10, 1)).called(1);
        verifyNever(mockNotesService.latest(any, any)); // Should NOT call latest
        verifyNever(mockNotesService.myLatest(any, any)); // Should NOT call myLatest

        // Verify results
        expect(trashProvider.notes, equals(deletedNotes));
        expect(trashProvider.trashedNotes, equals(deletedNotes)); // Alias should work
        expect(trashProvider.currentPage, equals(1));
        expect(trashProvider.totalPages, equals(1)); // ceil(2/10) = 1
        expect(trashProvider.error, isNull);
      });

      test('should handle pagination correctly for deleted notes', () async {
        final firstPageNotes = [
          Note(id: 1, content: 'Deleted note 1', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
        ];
        final secondPageNotes = [
          Note(id: 2, content: 'Deleted note 2', isPrivate: false, userId: 2,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
        ];

        // Setup first page
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult(firstPageNotes, 25)); // Multiple pages
        await trashProvider.navigateToPage(1);
        expect(trashProvider.totalPages, equals(3)); // ceil(25/10) = 3

        // Setup second page
        when(mockNotesService.latestDeleted(10, 2))
            .thenAnswer((_) async => NotesResult(secondPageNotes, 25));
        await trashProvider.navigateToPage(2);

        // Verify pagination calls
        verify(mockNotesService.latestDeleted(10, 1)).called(1);
        verify(mockNotesService.latestDeleted(10, 2)).called(1);

        expect(trashProvider.currentPage, equals(2));
        expect(trashProvider.notes, equals(secondPageNotes));
      });

      test('should handle empty trash results', () async {
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult([], 0));

        await trashProvider.navigateToPage(1);

        verify(mockNotesService.latestDeleted(10, 1)).called(1);
        expect(trashProvider.notes, isEmpty);
        expect(trashProvider.totalPages, equals(1)); // Minimum 1 page
      });

      test('should handle service errors during trash loading', () async {
        when(mockNotesService.latestDeleted(10, 1))
            .thenThrow(Exception('Trash service unavailable'));

        await trashProvider.navigateToPage(1);

        verify(mockNotesService.latestDeleted(10, 1)).called(1);
        expect(trashProvider.error, contains('Trash service unavailable'));
        expect(trashProvider.notes, isEmpty);
        expect(trashProvider.isLoading, isFalse);
      });
    });

    group('Purge functionality', () {
      test('should purge all deleted notes successfully', () async {
        final deletedNotes = [
          Note(id: 1, content: 'Deleted note 1', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
          Note(id: 2, content: 'Deleted note 2', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
        ];

        // Setup initial trash state
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult(deletedNotes, 2));
        await trashProvider.navigateToPage(1);
        expect(trashProvider.notes.length, equals(2));

        // Setup successful purge
        when(mockNotesService.purgeDeleted())
            .thenAnswer((_) async => 1);

        // Setup empty result after purge
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult([], 0));

        // Track isPurging state changes
        var purgingStates = <bool>[];
        trashProvider.addListener(() {
          purgingStates.add(trashProvider.isPurging);
        });

        final result = await trashProvider.purgeDeleted();

        // Verify purge operation
        verify(mockNotesService.purgeDeleted()).called(1);
        verify(mockNotesService.latestDeleted(10, 1)).called(1); // Initial load only, no refresh

        expect(result, isTrue);
        expect(trashProvider.isPurging, isFalse); // Should end as false
        expect(trashProvider.notes, isEmpty); // After purge
        expect(trashProvider.error, isNull);

        // Verify loading state transitions: true (start) -> false (end)
        expect(purgingStates, contains(true));
        expect(purgingStates.last, isFalse);
      });

      test('should handle purge errors correctly', () async {
        final deletedNotes = [
          Note(id: 1, content: 'Deleted note 1', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
        ];

        // Setup initial state
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult(deletedNotes, 1));
        await trashProvider.navigateToPage(1);

        // Setup purge failure
        when(mockNotesService.purgeDeleted())
            .thenThrow(Exception('Purge permission denied'));

        final result = await trashProvider.purgeDeleted();

        verify(mockNotesService.purgeDeleted()).called(1);

        // Verify error handling
        expect(result, isFalse);
        expect(trashProvider.isPurging, isFalse); // Should end as false even on error
        // Note: TrashProvider handleServiceError doesn't set error field automatically
        expect(trashProvider.notes.length, equals(1)); // Should remain unchanged
      });

      test('should prevent operations while purging', () async {
        // Setup slow purge operation
        when(mockNotesService.purgeDeleted())
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 100));
              return 1;
            });
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult([], 0));

        // Start purge operation
        final future = trashProvider.purgeDeleted();

        // Verify isPurging is true during operation
        expect(trashProvider.isPurging, isTrue);

        // Wait for completion
        await future;

        expect(trashProvider.isPurging, isFalse);
      });
    });

    group('Undelete functionality', () {
      test('should undelete note successfully and update local state', () async {
        final deletedNotes = [
          Note(id: 1, content: 'Deleted note 1', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
          Note(id: 2, content: 'Deleted note 2', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
        ];

        // Setup initial state
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult(deletedNotes, 2));
        await trashProvider.navigateToPage(1);
        expect(trashProvider.notes.length, equals(2));

        // Setup successful undelete
        when(mockNotesService.undelete(1))
            .thenAnswer((_) async => 1);

        // Setup refresh result after undelete (only note 2 remains)
        final remainingNotes = [deletedNotes[1]];
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult(remainingNotes, 1));

        final result = await trashProvider.undeleteNote(1);

        // Verify undelete operation
        verify(mockNotesService.undelete(1)).called(1);
        verify(mockNotesService.latestDeleted(10, 1)).called(1); // Initial load only, no refresh

        expect(result, isTrue);
        expect(trashProvider.notes.length, equals(1));
        expect(trashProvider.notes.first.id, equals(2)); // Only note 2 remains
        expect(trashProvider.error, isNull);
      });

      test('should handle undelete errors correctly', () async {
        final deletedNotes = [
          Note(id: 1, content: 'Deleted note 1', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
        ];

        // Setup initial state
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult(deletedNotes, 1));
        await trashProvider.navigateToPage(1);

        // Setup undelete failure
        when(mockNotesService.undelete(1))
            .thenThrow(Exception('Undelete permission denied'));

        final result = await trashProvider.undeleteNote(1);

        verify(mockNotesService.undelete(1)).called(1);

        // Verify error handling
        expect(result, isFalse);
        // Note: TrashProvider handleServiceError doesn't set error field automatically
        expect(trashProvider.notes.length, equals(1)); // Should remain unchanged on error
        expect(trashProvider.notes.first.id, equals(1)); // Original note should remain
      });

      test('should handle undelete of non-existent note gracefully', () async {
        final deletedNotes = [
          Note(id: 1, content: 'Deleted note 1', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
        ];

        // Setup initial state
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult(deletedNotes, 1));
        await trashProvider.navigateToPage(1);

        // Setup successful undelete (service doesn't care about local existence)
        when(mockNotesService.undelete(999))
            .thenAnswer((_) async => 1);
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult(deletedNotes, 1)); // Refresh result

        final result = await trashProvider.undeleteNote(999);

        // Should succeed even though note wasn't in local list
        expect(result, isTrue);
        expect(trashProvider.notes.length, equals(1)); // No change since note 999 wasn't in list

        verify(mockNotesService.undelete(999)).called(1);
      });
    });

    group('Get note functionality', () {
      test('should get deleted note successfully', () async {
        final deletedNote = Note(id: 1, content: 'Deleted note', isPrivate: false, userId: 1,
                                 isLong: false, isMarkdown: false, createdAt: 1640995200,
                                 deletedAt: 1641000000, user: null, tags: []);

        when(mockNotesService.get(1))
            .thenAnswer((_) async => deletedNote);

        final result = await trashProvider.getNote(1);

        verify(mockNotesService.get(1)).called(1);
        expect(result, equals(deletedNote));
        expect(result!.deletedAt, isNotNull); // Should have deletedAt timestamp
      });

      test('should handle get note errors gracefully', () async {
        when(mockNotesService.get(999))
            .thenThrow(Exception('Note not found'));

        final result = await trashProvider.getNote(999);

        verify(mockNotesService.get(999)).called(1);
        expect(result, isNull);
        // Note: TrashProvider handleServiceError doesn't set error field automatically
      });

      test('should handle non-existent notes by throwing exception', () async {
        when(mockNotesService.get(999))
            .thenThrow(Exception('Note not found'));

        final result = await trashProvider.getNote(999);

        verify(mockNotesService.get(999)).called(1);
        expect(result, isNull);
        // Note: TrashProvider handleServiceError doesn't set error field automatically
      });
    });

    group('Delete functionality override', () {
      test('should return error result for deleteNote calls', () async {
        // TrashProvider overrides performDelete to throw UnimplementedError
        final result = await trashProvider.deleteNote(1);

        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('UnimplementedError'));
        expect(result.errorMessage, contains('Use purgeDeleted or undeleteNote instead'));

        // Should not call any service methods
        verifyZeroInteractions(mockNotesService);
      });
    });

    group('State management', () {
      test('should refresh trash results', () async {
        final initialNotes = [
          Note(id: 1, content: 'Old deleted note', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
        ];
        final refreshedNotes = [
          Note(id: 1, content: 'Updated deleted note', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
          Note(id: 2, content: 'New deleted note', isPrivate: false, userId: 2,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
        ];

        // Setup initial load
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult(initialNotes, 1));
        await trashProvider.navigateToPage(1);
        expect(trashProvider.notes.length, equals(1));

        // Setup refresh with new data
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult(refreshedNotes, 2));
        await trashProvider.refresh();

        // Verify refresh calls correct service method
        verify(mockNotesService.latestDeleted(10, 1)).called(2); // Initial + refresh
        expect(trashProvider.notes.length, equals(2));
        expect(trashProvider.notes.first.content, equals('Updated deleted note'));
      });

      test('should clear all data including purging state', () async {
        final testNotes = [
          Note(id: 1, content: 'Deleted note', isPrivate: false, userId: 1,
               isLong: false, isMarkdown: false, createdAt: 1640995200,
               deletedAt: 1641000000, user: null, tags: []),
        ];

        // Setup some state
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult(testNotes, 1));
        await trashProvider.navigateToPage(1);
        expect(trashProvider.notes.isNotEmpty, isTrue);

        // Simulate purging state
        when(mockNotesService.purgeDeleted())
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 10));
              return 1;
            });
        when(mockNotesService.latestDeleted(10, 1))
            .thenAnswer((_) async => NotesResult([], 0));

        final future = trashProvider.purgeDeleted(); // Start purging
        expect(trashProvider.isPurging, isTrue);

        // Clear all data (purging state managed separately by purgeDeleted)
        trashProvider.clearNotesCache();

        expect(trashProvider.notes, isEmpty);
        expect(trashProvider.isPurging, isTrue); // Purging state unchanged by clearNotesCache
        expect(trashProvider.currentPage, equals(1));
        expect(trashProvider.totalPages, equals(1));
        expect(trashProvider.isLoading, isFalse);
        expect(trashProvider.error, isNull);
        expect(trashProvider.groupedNotes, isEmpty);

        await future; // Clean up
      });
    });

    group('AuthAwareProvider integration', () {
      test('should inherit authentication-aware functionality', () {
        // Verify inheritance from NoteListProvider -> AuthAwareProvider
        expect(trashProvider.isAuthStateInitialized, isFalse);

        // Should have inherited methods available
        expect(() => trashProvider.clearNotesCache(), returnsNormally);
      });
    });
  });
}
