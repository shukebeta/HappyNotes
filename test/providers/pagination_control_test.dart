import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/notes_provider.dart';
import 'package:happy_notes/providers/memories_provider.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/services/seq_logger.dart';

import 'notes_provider_test.mocks.dart';

void main() {
  group('Pagination Control Tests', () {
    late MockNotesService mockNotesService;

    setUp(() {
      // Initialize SeqLogger for tests
      SeqLogger.initialize(enabled: false);

      mockNotesService = MockNotesService();
    });

    group('NotesProvider - Pagination Enabled', () {
      late NotesProvider notesProvider;

      setUp(() {
        notesProvider = NotesProvider(mockNotesService);
      });

      test('should initialize with pagination enabled by default', () {
        expect(notesProvider.autoPageEnabled, isTrue);
      });

      test('canAutoLoadNext should return true when conditions are met', () async {
        // Mock multi-page scenario
        final notes = List.generate(10, (i) => Note(
          id: i + 1,
          content: 'Note ${i + 1}',
          isPrivate: false,
          userId: 1,
          isLong: false,
          isMarkdown: false,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ));
        final result = NotesResult(notes, 25); // 25 total notes, 3 pages

        when(mockNotesService.myLatest(any, any))
            .thenAnswer((_) async => result);

        // Load first page and wait for completion
        await notesProvider.navigateToPage(1);

        // Should be able to load next page
        expect(notesProvider.canAutoLoadNext(), isTrue);
      });

      test('canAutoLoadNext should return false when pagination disabled', () {
        notesProvider.setAutoPageEnabled(false);
        expect(notesProvider.canAutoLoadNext(), isFalse);
      });

      test('canAutoLoadPrevious should return true when on page > 1', () async {
        // Mock multi-page scenario and navigate to page 2
        final notes = List.generate(10, (i) => Note(
          id: i + 1,
          content: 'Note ${i + 1}',
          isPrivate: false,
          userId: 1,
          isLong: false,
          isMarkdown: false,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ));
        final result = NotesResult(notes, 25);

        when(mockNotesService.myLatest(any, any))
            .thenAnswer((_) async => result);

        // First navigate to page 1 to establish total pages
        await notesProvider.navigateToPage(1);

        // Then navigate to page 2 and wait for completion
        await notesProvider.navigateToPage(2);

        expect(notesProvider.canAutoLoadPrevious(), isTrue);
      });

      test('canAutoLoadPrevious should return false when pagination disabled', () {
        notesProvider.setAutoPageEnabled(false);
        expect(notesProvider.canAutoLoadPrevious(), isFalse);
      });
    });

    group('MemoriesProvider - Pagination Disabled', () {
      late MemoriesProvider memoriesProvider;

      setUp(() {
        memoriesProvider = MemoriesProvider(mockNotesService);
      });

      test('should initialize with pagination disabled', () {
        expect(memoriesProvider.autoPageEnabled, isFalse);
      });

      test('canAutoLoadNext should always return false', () {
        // Even with data that would normally support pagination
        const testDate = '20250812';
        final notes = List.generate(50, (i) => Note(
          id: i + 1,
          content: 'Memory ${i + 1}',
          isPrivate: false,
          userId: 1,
          isLong: false,
          isMarkdown: false,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ));

        when(mockNotesService.memoriesOn(testDate))
            .thenAnswer((_) async => NotesResult(notes, notes.length));

        memoriesProvider.setCurrentDate(testDate);
        memoriesProvider.loadMemoriesForDate(testDate);

        expect(memoriesProvider.canAutoLoadNext(), isFalse);
      });

      test('canAutoLoadPrevious should always return false', () {
        expect(memoriesProvider.canAutoLoadPrevious(), isFalse);
      });

      test('should maintain pagination disabled even when manually enabled', () {
        memoriesProvider.setAutoPageEnabled(true);

        // autoPageEnabled property might be true, but auto-load methods should still return false
        expect(memoriesProvider.autoPageEnabled, isTrue);
        expect(memoriesProvider.canAutoLoadNext(), isFalse);
        expect(memoriesProvider.canAutoLoadPrevious(), isFalse);
      });
    });

    group('Cross-Provider Pagination Behavior Comparison', () {
      late NotesProvider notesProvider;
      late MemoriesProvider memoriesProvider;

      setUp(() {
        notesProvider = NotesProvider(mockNotesService);
        memoriesProvider = MemoriesProvider(mockNotesService);
      });

      test('NotesProvider should support pagination while MemoriesProvider should not', () {
        // Both start with their default pagination settings
        expect(notesProvider.autoPageEnabled, isTrue);
        expect(memoriesProvider.autoPageEnabled, isFalse);

        // NotesProvider should support auto-load when conditions are met
        // (This would be true in a real scenario with multi-page data)
        expect(notesProvider.canAutoLoadNext(), isFalse); // False because no data loaded yet
        expect(notesProvider.canAutoLoadPrevious(), isFalse);

        // MemoriesProvider should never support auto-load
        expect(memoriesProvider.canAutoLoadNext(), isFalse);
        expect(memoriesProvider.canAutoLoadPrevious(), isFalse);
      });

      test('setAutoPageEnabled should affect providers differently', () {
        // Enable pagination for both
        notesProvider.setAutoPageEnabled(true);
        memoriesProvider.setAutoPageEnabled(true);

        expect(notesProvider.autoPageEnabled, isTrue);
        expect(memoriesProvider.autoPageEnabled, isTrue);

        // Disable pagination for both
        notesProvider.setAutoPageEnabled(false);
        memoriesProvider.setAutoPageEnabled(false);

        expect(notesProvider.autoPageEnabled, isFalse);
        expect(memoriesProvider.autoPageEnabled, isFalse);

        // Both should now return false for auto-load methods
        expect(notesProvider.canAutoLoadNext(), isFalse);
        expect(notesProvider.canAutoLoadPrevious(), isFalse);
        expect(memoriesProvider.canAutoLoadNext(), isFalse);
        expect(memoriesProvider.canAutoLoadPrevious(), isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle pagination state correctly when loading', () async {
        final notesProvider = NotesProvider(mockNotesService);

        // Mock a slow loading response
        when(mockNotesService.myLatest(any, any))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 10));
              return NotesResult([], 0);
            });

        // Start loading and check state before completion
        final loadFuture = notesProvider.navigateToPage(1);

        // Give it a moment to start loading
        await Future.delayed(const Duration(milliseconds: 1));

        expect(notesProvider.isLoading, isTrue);
        expect(notesProvider.canAutoLoadNext(), isFalse);
        expect(notesProvider.canAutoLoadPrevious(), isFalse);

        // Wait for completion
        await loadFuture;
      });

      test('should handle pagination state correctly during auto-loading', () async {
        final notesProvider = NotesProvider(mockNotesService);

        final notes = List.generate(10, (i) => Note(
          id: i + 1,
          content: 'Note ${i + 1}',
          isPrivate: false,
          userId: 1,
          isLong: false,
          isMarkdown: false,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ));
        final result = NotesResult(notes, 25);

        when(mockNotesService.myLatest(any, any))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 10));
              return result;
            });

        // Load initial page
        await notesProvider.navigateToPage(1);

        // Start auto-loading and check state immediately
        final autoLoadFuture = notesProvider.autoLoadNext();

        // The auto-loading should be active immediately
        expect(notesProvider.isAutoLoading, isTrue);
        expect(notesProvider.canAutoLoadNext(), isFalse);
        expect(notesProvider.canAutoLoadPrevious(), isFalse);

        // Wait for completion
        await autoLoadFuture;
      });
    });
  });
}
