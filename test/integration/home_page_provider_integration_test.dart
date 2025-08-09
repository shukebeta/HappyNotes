import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/notes_provider.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';

// Import the mocks
import '../providers/notes_provider_test.mocks.dart';

void main() {
  group('Provider-Consumer Integration Tests', () {
    late MockNotesService mockNotesService;
    late NotesProvider notesProvider;

    final mockNotes = [
      Note(
        id: 1,
        userId: 123,
        content: 'Integration test note 1',
        isPrivate: false,
        isMarkdown: false,
        isLong: false,
        createdAt: 1640995200,
        deletedAt: null,
        user: null,
        tags: [],
      ),
      Note(
        id: 2,
        userId: 123,
        content: 'Integration test note 2',
        isPrivate: true,
        isMarkdown: true,
        isLong: true,
        createdAt: 1640995260,
        deletedAt: null,
        user: null,
        tags: [],
      ),
    ];

    setUp(() {
      mockNotesService = MockNotesService();
      notesProvider = NotesProvider(mockNotesService);

      // Setup default mock responses
      when(mockNotesService.myLatest(any, any))
          .thenAnswer((_) async => NotesResult(mockNotes, 2));
    });

    test('provider should integrate properly with listeners', () async {
      var notificationCount = 0;
      notesProvider.addListener(() => notificationCount++);

      await notesProvider.loadPage(1);
      
      // Verify integration between provider and service
      verify(mockNotesService.myLatest(10, 1)).called(1);
      expect(notesProvider.notes.length, 2);
      expect(notesProvider.currentPage, 1);
      expect(notificationCount, greaterThan(0));
    });

    test('provider should handle CRUD operations correctly', () async {
      // Initial load
      await notesProvider.loadPage(1);
      expect(notesProvider.notes.length, 2);

      // Mock update operation
      when(mockNotesService.update(1, 'Updated content', false, false))
          .thenAnswer((_) async => 1);

      // Update note
      final success = await notesProvider.updateNote(1, 'Updated content');
      expect(success, isTrue);
      expect(notesProvider.notes.first.content, 'Updated content');
    });

    test('provider should handle pagination correctly', () async {
      // Setup mock for multiple pages
      when(mockNotesService.myLatest(10, 1))
          .thenAnswer((_) async => NotesResult([mockNotes[0]], 2));
      when(mockNotesService.myLatest(10, 2))
          .thenAnswer((_) async => NotesResult([mockNotes[1]], 2));

      // Load page 1
      await notesProvider.loadPage(1);
      expect(notesProvider.currentPage, 1);
      expect(notesProvider.notes.length, 1);
      verify(mockNotesService.myLatest(10, 1)).called(1);

      // Load page 2
      await notesProvider.loadPage(2);
      expect(notesProvider.currentPage, 2);
      expect(notesProvider.notes.length, 1);
      verify(mockNotesService.myLatest(10, 2)).called(1);
    });

    test('provider should handle loading states correctly', () async {
      // Setup delayed mock response
      when(mockNotesService.myLatest(any, any))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return NotesResult(mockNotes, 2);
      });

      // Start loading
      final loadFuture = notesProvider.loadPage(1);
      expect(notesProvider.isLoadingList, isTrue);
      
      // Wait for completion
      await loadFuture;
      expect(notesProvider.isLoadingList, isFalse);
      expect(notesProvider.notes.length, 2);
    });

    test('provider should handle error states correctly', () async {
      // Setup mock to throw error
      when(mockNotesService.myLatest(any, any))
          .thenThrow(Exception('Network error'));

      await notesProvider.loadPage(1);

      // Verify error is handled gracefully
      expect(notesProvider.listError, isNotNull);
      expect(notesProvider.listError, contains('Network error'));
      expect(notesProvider.notes, isEmpty);
      expect(notesProvider.isLoadingList, isFalse);
    });
  });
}