import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/providers/note_list_provider.dart';
import 'package:happy_notes/services/notes_services.dart';

import 'notes_provider_test.mocks.dart';

/// Test implementation of NoteListProvider for testing abstract base class
class TestNoteListProvider extends NoteListProvider {
  final MockNotesService mockNotesService;

  TestNoteListProvider(this.mockNotesService);

  @override
  NotesService get notesService => mockNotesService;

  @override
  Future<NotesResult> fetchNotes(int pageSize, int pageNumber) async {
    return await mockNotesService.myLatest(pageSize, pageNumber);
  }

  @override
  Future<void> performDelete(int noteId) async {
    await mockNotesService.delete(noteId);
  }
}

void main() {
  group('NoteListProvider Base Class Tests', () {
    late TestNoteListProvider provider;
    late MockNotesService mockNotesService;

    setUp(() {
      mockNotesService = MockNotesService();
      provider = TestNoteListProvider(mockNotesService);
    });

    group('Initialization', () {
      test('should initialize with correct default values', () {
        expect(provider.notes, isEmpty);
        expect(provider.currentPage, equals(1));
        expect(provider.totalPages, equals(1));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        expect(provider.groupedNotes, isEmpty);
        expect(provider.autoPageEnabled, isTrue);
        expect(provider.isAutoLoading, isFalse);
      });
    });

    group('Auto-pagination', () {
      test('should initialize with auto-page enabled', () {
        expect(provider.autoPageEnabled, isTrue);
        expect(provider.isAutoLoading, isFalse);
      });

      test('should be able to disable auto-pagination', () {
        provider.setAutoPageEnabled(false);
        expect(provider.autoPageEnabled, isFalse);
      });
    });

    group('Pagination Navigation', () {
      test('should navigate to valid page successfully', () async {
        final testNotes = [
          Note(
              id: 1,
              content: 'Test note 1',
              isPrivate: false,
              userId: 1,
              isLong: false,
              isMarkdown: false,
              createdAt: 1640995200,
              deletedAt: null,
              user: null,
              tags: []),
        ];
        final result = NotesResult(testNotes, 25); // More notes to create multiple pages

        // First, setup state with multiple pages by loading page 1
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => result);
        await provider.navigateToPage(1);
        expect(provider.totalPages, equals(3)); // ceil(25/10) = 3

        // Now navigate to page 2
        when(mockNotesService.myLatest(10, 2)).thenAnswer((_) async => NotesResult(testNotes, 25));
        await provider.navigateToPage(2);

        expect(provider.currentPage, equals(2));
        expect(provider.notes, equals(testNotes));
        expect(provider.totalPages, equals(3)); // ceil(25/10) = 3
        expect(provider.error, isNull);
        expect(provider.isLoading, isFalse);
      });

      test('should not navigate to invalid page numbers', () async {
        // Setup current state
        final result = NotesResult([], 10);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => result);
        await provider.navigateToPage(1);

        // Try invalid page numbers
        await provider.navigateToPage(-1);
        expect(provider.currentPage, equals(1)); // Should remain unchanged

        await provider.navigateToPage(0);
        expect(provider.currentPage, equals(1)); // Should remain unchanged

        await provider.navigateToPage(99);
        expect(provider.currentPage, equals(1)); // Should remain unchanged (beyond totalPages)

        // Verify service was not called for invalid pages
        verifyNever(mockNotesService.myLatest(10, -1));
        verifyNever(mockNotesService.myLatest(10, 0));
        verifyNever(mockNotesService.myLatest(10, 99));
      });

      test('should prevent navigation when loading', () async {
        // Setup a slow service call
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return NotesResult([], 0);
        });

        // Start first navigation (will be loading)
        final future1 = provider.navigateToPage(1);

        // Try to navigate again while loading
        await provider.navigateToPage(2);

        // Wait for first navigation to complete
        await future1;

        // Should have only called service once (for page 1)
        verify(mockNotesService.myLatest(10, 1)).called(1);
        verifyNever(mockNotesService.myLatest(10, 2));
      });

      test('should handle navigation errors correctly', () async {
        when(mockNotesService.myLatest(10, 1)).thenThrow(Exception('Network error'));

        await provider.navigateToPage(1);

        expect(provider.error, contains('Network error'));
        expect(provider.isLoading, isFalse);
        expect(provider.notes, isEmpty);
        expect(provider.currentPage, equals(1)); // Page should remain as requested
      });
    });

    group('Refresh functionality', () {
      test('should refresh current page', () async {
        final initialNotes = [
          Note(
              id: 1,
              content: 'Old content',
              isPrivate: false,
              userId: 1,
              isLong: false,
              isMarkdown: false,
              createdAt: 1640995200,
              deletedAt: null,
              user: null,
              tags: []),
        ];
        final refreshedNotes = [
          Note(
              id: 1,
              content: 'Updated content',
              isPrivate: false,
              userId: 1,
              isLong: false,
              isMarkdown: false,
              createdAt: 1640995200,
              deletedAt: null,
              user: null,
              tags: []),
        ];

        // Setup state with multiple pages first
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult([], 25)); // Create multiple pages
        await provider.navigateToPage(1);

        // Setup initial load for page 2
        when(mockNotesService.myLatest(10, 2)).thenAnswer((_) async => NotesResult(initialNotes, 25));
        await provider.navigateToPage(2);
        expect(provider.notes.first.content, equals('Old content'));

        // Setup refresh with updated data
        when(mockNotesService.myLatest(10, 2)).thenAnswer((_) async => NotesResult(refreshedNotes, 1));
        await provider.refresh();

        expect(provider.currentPage, equals(2)); // Should stay on same page
        expect(provider.notes.first.content, equals('Updated content'));

        // Verify service was called for same page
        verify(mockNotesService.myLatest(10, 2)).called(2);
      });
    });

    group('Date grouping functionality', () {
      test('should group notes by date correctly', () async {
        final testNotes = [
          Note(
              id: 1,
              content: 'Note 1',
              isPrivate: false,
              userId: 1,
              isLong: false,
              isMarkdown: false,
              createdAt: 1640995200, // 2022-01-01
              deletedAt: null,
              user: null,
              tags: []),
          Note(
              id: 2,
              content: 'Note 2',
              isPrivate: false,
              userId: 1,
              isLong: false,
              isMarkdown: false,
              createdAt: 1641081600, // 2022-01-02
              deletedAt: null,
              user: null,
              tags: []),
          Note(
              id: 3,
              content: 'Note 3',
              isPrivate: false,
              userId: 1,
              isLong: false,
              isMarkdown: false,
              createdAt: 1640995200, // 2022-01-01 (same as note 1)
              deletedAt: null,
              user: null,
              tags: []),
        ];

        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult(testNotes, 3));

        await provider.navigateToPage(1);

        final grouped = provider.groupedNotes;
        expect(grouped.keys.length, equals(2)); // Two different dates
        expect(grouped.keys, contains('2022-01-01'));
        expect(grouped.keys, contains('2022-01-02'));
        expect(grouped['2022-01-01']?.length, equals(2)); // Note 1 and Note 3
        expect(grouped['2022-01-02']?.length, equals(1)); // Note 2
      });

      test('should return empty groupedNotes when no notes loaded', () {
        expect(provider.groupedNotes, isEmpty);
      });
    });

    group('Optimistic delete with rollback', () {
      test('should perform optimistic delete successfully', () async {
        final testNotes = [
          Note(
              id: 1,
              content: 'Note 1',
              isPrivate: false,
              userId: 1,
              isLong: false,
              isMarkdown: false,
              createdAt: 1640995200,
              deletedAt: null,
              user: null,
              tags: []),
          Note(
              id: 2,
              content: 'Note 2',
              isPrivate: false,
              userId: 1,
              isLong: false,
              isMarkdown: false,
              createdAt: 1640995200,
              deletedAt: null,
              user: null,
              tags: []),
        ];

        // Setup initial state
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult(testNotes, 2));
        await provider.navigateToPage(1);
        expect(provider.notes.length, equals(2));

        // Setup successful delete
        when(mockNotesService.delete(1)).thenAnswer((_) async => 1);

        final result = await provider.deleteNote(1);

        expect(result.isSuccess, isTrue);
        expect(provider.notes.length, equals(1));
        expect(provider.notes.first.id, equals(2));

        verify(mockNotesService.delete(1)).called(1);
      });

      test('should rollback optimistic delete on failure', () async {
        final testNotes = [
          Note(
              id: 1,
              content: 'Note 1',
              isPrivate: false,
              userId: 1,
              isLong: false,
              isMarkdown: false,
              createdAt: 1640995200,
              deletedAt: null,
              user: null,
              tags: []),
          Note(
              id: 2,
              content: 'Note 2',
              isPrivate: false,
              userId: 1,
              isLong: false,
              isMarkdown: false,
              createdAt: 1640995200,
              deletedAt: null,
              user: null,
              tags: []),
        ];

        // Setup initial state
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult(testNotes, 2));
        await provider.navigateToPage(1);
        expect(provider.notes.length, equals(2));

        // Setup delete failure
        when(mockNotesService.delete(1)).thenThrow(Exception('Delete failed'));

        final result = await provider.deleteNote(1);

        // Should rollback to original state
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Delete failed'));
        expect(provider.notes.length, equals(2)); // Rolled back
        expect(provider.notes.map((n) => n.id), containsAll([1, 2])); // Both notes restored

        verify(mockNotesService.delete(1)).called(1);
      });

      test('should handle delete of non-existent note gracefully', () async {
        final testNotes = [
          Note(
              id: 1,
              content: 'Note 1',
              isPrivate: false,
              userId: 1,
              isLong: false,
              isMarkdown: false,
              createdAt: 1640995200,
              deletedAt: null,
              user: null,
              tags: []),
        ];

        // Setup initial state
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult(testNotes, 1));
        await provider.navigateToPage(1);

        // Setup successful delete (service doesn't care about existence)
        when(mockNotesService.delete(999)).thenAnswer((_) async => 1);

        final result = await provider.deleteNote(999);

        // Should succeed even though note wasn't in local list
        expect(result.isSuccess, isTrue);
        expect(provider.notes.length, equals(1)); // No change since note 999 wasn't in list

        verify(mockNotesService.delete(999)).called(1);
      });
    });

    group('State management', () {
      test('should clear all data correctly', () async {
        final testNotes = [
          Note(
              id: 1,
              content: 'Note 1',
              isPrivate: false,
              userId: 1,
              isLong: false,
              isMarkdown: false,
              createdAt: 1640995200,
              deletedAt: null,
              user: null,
              tags: []),
        ];

        // Setup state with multiple pages first
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult([], 25)); // Create multiple pages
        await provider.navigateToPage(1);

        // Setup some state
        when(mockNotesService.myLatest(10, 2)).thenAnswer((_) async => NotesResult(testNotes, 25));
        await provider.navigateToPage(2);
        expect(provider.notes.isNotEmpty, isTrue);
        expect(provider.currentPage, equals(2));

        // Clear all data
        provider.clearNotesCache();

        expect(provider.notes, isEmpty);
        expect(provider.currentPage, equals(1));
        expect(provider.totalPages, equals(1));
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        expect(provider.groupedNotes, isEmpty);
      });

      test('should calculate totalPages correctly', () async {
        // Test various total note counts
        final testCases = [
          (0, 1), // 0 notes -> 1 page (minimum)
          (5, 1), // 5 notes -> 1 page
          (10, 1), // 10 notes -> 1 page (exactly pageSize)
          (15, 2), // 15 notes -> 2 pages
          (25, 3), // 25 notes -> 3 pages
        ];

        for (final (totalNotes, expectedPages) in testCases) {
          when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => NotesResult([], totalNotes));

          await provider.navigateToPage(1);
          expect(provider.totalPages, equals(expectedPages),
              reason: '$totalNotes notes should result in $expectedPages pages');
        }
      });
    });

    group('AuthAwareProvider integration', () {
      test('should inherit auth-aware functionality', () {
        // Test that the provider extends AuthAwareProvider
        expect(provider.isAuthStateInitialized, isFalse);

        // clearNotesCache should be callable (inherited method)
        expect(() => provider.clearNotesCache(), returnsNormally);
      });
    });
  });
}
