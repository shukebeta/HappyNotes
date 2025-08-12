import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/notes_provider.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';

import '../providers/notes_provider_test.mocks.dart';

void main() {
  group('NotesProvider Performance Tests', () {
    late NotesProvider provider;
    late MockNotesService mockNotesService;

    setUp(() {
      mockNotesService = MockNotesService();
      provider = NotesProvider(mockNotesService);
    });

    test('should efficiently handle large datasets', () async {
      // Generate large dataset
      final largeNotesList = List.generate(1000, (index) => Note(
        id: index + 1,
        userId: 123,
        content: 'Performance test note ${index + 1}',
        isPrivate: index % 2 == 0,
        isMarkdown: index % 3 == 0,
        isLong: index % 4 == 0,
        createdAt: 1640995200 + index * 60,
        deletedAt: null,
        user: null,
        tags: [],
      ));

      when(mockNotesService.myLatest(10, 1))
          .thenAnswer((_) async => NotesResult(largeNotesList.take(10).toList(), 1000));

      final stopwatch = Stopwatch()..start();

      await provider.loadPage(1);

      stopwatch.stop();

      expect(provider.notes.length, 10);
      expect(provider.totalPages, 100);
      expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast

      // Test grouping performance with large dataset
      stopwatch.reset();
      stopwatch.start();

      final grouped = provider.groupedNotes;

      stopwatch.stop();

      expect(grouped.isNotEmpty, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Grouping should be fast
    });

    test('should optimize memory usage with pagination', () async {
      const pageSize = 10;
      final mockNotes = List.generate(pageSize, (index) => Note(
        id: index + 1,
        userId: 123,
        content: 'Memory test note ${index + 1}',
        isPrivate: false,
        isMarkdown: false,
        isLong: false,
        createdAt: 1640995200 + index * 60,
        deletedAt: null,
        user: null,
        tags: [],
      ));

      when(mockNotesService.myLatest(pageSize, any))
          .thenAnswer((invocation) async {
        final page = invocation.positionalArguments[1] as int;
        final startIndex = (page - 1) * pageSize;
        return NotesResult(
          mockNotes.map((note) => Note(
            id: note.id + startIndex,
            userId: note.userId,
            content: '${note.content} Page $page',
            isPrivate: note.isPrivate,
            isMarkdown: note.isMarkdown,
            isLong: note.isLong,
            createdAt: note.createdAt + startIndex * 60,
            deletedAt: note.deletedAt,
            user: note.user,
            tags: note.tags,
          )).toList(),
          1000,
        );
      });

      // Load multiple pages rapidly
      final stopwatch = Stopwatch()..start();

      for (int page = 1; page <= 10; page++) {
        await provider.loadPage(page);
      }

      stopwatch.stop();

      // Should maintain only current page in memory, not all pages
      expect(provider.notes.length, pageSize);
      expect(provider.currentPage, 10);
      expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Should be reasonable
    });

    test('should debounce rapid successive calls', () async {
      when(mockNotesService.myLatest(10, 1))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return NotesResult([], 0);
      });

      final stopwatch = Stopwatch()..start();

      // Fire 20 rapid successive calls
      final futures = List.generate(20, (_) => provider.loadPage(1));
      await Future.wait(futures);

      stopwatch.stop();

      // Should have debounced/coalesced calls
      verify(mockNotesService.myLatest(10, 1)).called(1);
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('should efficiently update cache without full reload', () async {
      final initialNotes = List.generate(5, (index) => Note(
        id: index + 1,
        userId: 123,
        content: 'Initial note ${index + 1}',
        isPrivate: false,
        isMarkdown: false,
        isLong: false,
        createdAt: 1640995200 + index * 60,
        deletedAt: null,
        user: null,
        tags: [],
      ));

      when(mockNotesService.myLatest(10, 1))
          .thenAnswer((_) async => NotesResult(initialNotes, 5));
      when(mockNotesService.update(1, 'Updated content', false, false))
          .thenAnswer((_) async => 1); // Returns note ID

      // Initial load
      await provider.loadPage(1);

      var notificationCount = 0;
      provider.addListener(() => notificationCount++);

      final stopwatch = Stopwatch()..start();

      // Update note - should be fast cache update, not full reload
      await provider.updateNote(1, 'Updated content');

      stopwatch.stop();

      expect(provider.notes.first.content, 'Updated content');
      expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should be very fast
      expect(notificationCount, equals(1)); // Should notify only once

      // Should not have called myLatest again
      verify(mockNotesService.myLatest(10, 1)).called(1); // Only the initial load
    });

    test('should handle listener notifications efficiently', () async {
      when(mockNotesService.myLatest(10, 1))
          .thenAnswer((_) async => NotesResult([], 0));

      var listenerCallCount = 0;
      final stopwatch = Stopwatch();

      // Add multiple listeners
      for (int i = 0; i < 100; i++) {
        provider.addListener(() {
          stopwatch.start();
          listenerCallCount++;
          stopwatch.stop();
        });
      }

      await provider.loadPage(1);

      // All listeners should be called efficiently
      expect(listenerCallCount, 300); // Three notifications per listener (start loading, end loading, data update)
      expect(stopwatch.elapsedMilliseconds, lessThan(50)); // Should be fast even with many listeners
    });

    test('should clean up resources properly', () async {
      when(mockNotesService.myLatest(10, 1))
          .thenAnswer((_) async => NotesResult([], 0));

      // Add listeners
      void listener1() {}
      void listener2() {}
      void listener3() {}

      provider.addListener(listener1);
      provider.addListener(listener2);
      provider.addListener(listener3);

      await provider.loadPage(1);

      // Remove listeners
      provider.removeListener(listener1);
      provider.removeListener(listener2);
      provider.removeListener(listener3);

      // Clear all data
      provider.clearAllData();

      // Provider should be in clean state
      expect(provider.notes, isEmpty);
      expect(provider.groupedNotes, isEmpty);
      expect(provider.currentPage, 1);
      expect(provider.currentPage, 1);
    });
  });
}