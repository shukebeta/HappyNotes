import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/discovery_provider.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';

import 'notes_provider_test.mocks.dart';

void main() {
  group('DiscoveryProvider Tests', () {
    late DiscoveryProvider discoveryProvider;
    late MockNotesService mockNotesService;

    setUp(() {
      mockNotesService = MockNotesService();
      discoveryProvider = DiscoveryProvider(mockNotesService);
    });

    group('Initialization', () {
      test('should initialize with correct default values', () {
        expect(discoveryProvider.notes, isEmpty);
        expect(discoveryProvider.currentPage, equals(1));
        expect(discoveryProvider.totalPages, equals(1));
        expect(discoveryProvider.isLoading, isFalse);
        expect(discoveryProvider.error, isNull);
        expect(discoveryProvider.groupedNotes, isEmpty);
      });

      test('should extend NoteListProvider', () {
        // Verify inheritance of core functionality
        expect(discoveryProvider.notes, isA<List<Note>>());
        expect(discoveryProvider.currentPage, isA<int>());
        expect(discoveryProvider.totalPages, isA<int>());
        expect(discoveryProvider.isLoading, isA<bool>());
        expect(discoveryProvider.error, anyOf(isNull, isA<String>()));
        expect(discoveryProvider.groupedNotes, isA<Map<String, List<Note>>>());
      });
    });

    group('Public notes discovery', () {
      test('should fetch public notes using latest() service method', () async {
        final publicNotes = [
          Note(id: 1, content: 'Public note 1', isPrivate: false, userId: 1, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: []),
          Note(id: 2, content: 'Public note 2', isPrivate: false, userId: 2, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: []),
        ];
        final result = NotesResult(publicNotes, 2);
        
        when(mockNotesService.latest(10, 1))
            .thenAnswer((_) async => result);

        await discoveryProvider.navigateToPage(1);

        // Verify correct service method was called
        verify(mockNotesService.latest(10, 1)).called(1);
        verifyNever(mockNotesService.myLatest(any, any)); // Should NOT call myLatest
        
        // Verify results
        expect(discoveryProvider.notes, equals(publicNotes));
        expect(discoveryProvider.currentPage, equals(1));
        expect(discoveryProvider.totalPages, equals(1)); // ceil(2/10) = 1
        expect(discoveryProvider.error, isNull);
      });

      test('should handle pagination correctly for public notes', () async {
        final firstPageNotes = [
          Note(id: 1, content: 'Public note 1', isPrivate: false, userId: 1, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: []),
        ];
        final secondPageNotes = [
          Note(id: 2, content: 'Public note 2', isPrivate: false, userId: 2, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: []),
        ];

        // Setup first page
        when(mockNotesService.latest(10, 1))
            .thenAnswer((_) async => NotesResult(firstPageNotes, 25)); // Multiple pages
        await discoveryProvider.navigateToPage(1);
        expect(discoveryProvider.totalPages, equals(3)); // ceil(25/10) = 3
        
        // Setup second page
        when(mockNotesService.latest(10, 2))
            .thenAnswer((_) async => NotesResult(secondPageNotes, 25));
        await discoveryProvider.navigateToPage(2);

        // Verify pagination calls
        verify(mockNotesService.latest(10, 1)).called(1);
        verify(mockNotesService.latest(10, 2)).called(1);
        
        expect(discoveryProvider.currentPage, equals(2));
        expect(discoveryProvider.notes, equals(secondPageNotes));
      });

      test('should handle empty public notes results', () async {
        when(mockNotesService.latest(10, 1))
            .thenAnswer((_) async => NotesResult([], 0));

        await discoveryProvider.navigateToPage(1);

        verify(mockNotesService.latest(10, 1)).called(1);
        expect(discoveryProvider.notes, isEmpty);
        expect(discoveryProvider.totalPages, equals(1)); // Minimum 1 page
      });

      test('should handle service errors during discovery', () async {
        when(mockNotesService.latest(10, 1))
            .thenThrow(Exception('Discovery service unavailable'));

        await discoveryProvider.navigateToPage(1);

        verify(mockNotesService.latest(10, 1)).called(1);
        expect(discoveryProvider.error, contains('Discovery service unavailable'));
        expect(discoveryProvider.notes, isEmpty);
        expect(discoveryProvider.isLoading, isFalse);
      });
    });

    group('Delete functionality', () {
      test('should delete public notes using correct service method', () async {
        final testNotes = [
          Note(id: 1, content: 'Public note 1', isPrivate: false, userId: 1, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: []),
          Note(id: 2, content: 'Public note 2', isPrivate: false, userId: 1, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: []),
        ];
        
        // Setup initial state
        when(mockNotesService.latest(10, 1))
            .thenAnswer((_) async => NotesResult(testNotes, 2));
        await discoveryProvider.navigateToPage(1);
        expect(discoveryProvider.notes.length, equals(2));

        // Setup successful delete
        when(mockNotesService.delete(1))
            .thenAnswer((_) async => 1);

        final result = await discoveryProvider.deleteNote(1);

        // Verify correct delete method was called
        verify(mockNotesService.delete(1)).called(1);
        
        // Verify optimistic update (inherited from NoteListProvider)
        expect(result.isSuccess, isTrue);
        expect(discoveryProvider.notes.length, equals(1));
        expect(discoveryProvider.notes.first.id, equals(2));
      });

      test('should handle delete errors with rollback', () async {
        final testNotes = [
          Note(id: 1, content: 'Public note 1', isPrivate: false, userId: 1, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: []),
        ];
        
        // Setup initial state
        when(mockNotesService.latest(10, 1))
            .thenAnswer((_) async => NotesResult(testNotes, 1));
        await discoveryProvider.navigateToPage(1);

        // Setup delete failure
        when(mockNotesService.delete(1))
            .thenThrow(Exception('Delete permission denied'));

        final result = await discoveryProvider.deleteNote(1);

        verify(mockNotesService.delete(1)).called(1);
        
        // Verify rollback (inherited from NoteListProvider)
        expect(result.isSuccess, isFalse);
        expect(result.errorMessage, contains('Delete permission denied'));
        expect(discoveryProvider.notes.length, equals(1)); // Rolled back
        expect(discoveryProvider.notes.first.id, equals(1)); // Original note restored
      });
    });

    group('State management', () {
      test('should refresh discovery results', () async {
        final initialNotes = [
          Note(id: 1, content: 'Old public note', isPrivate: false, userId: 1, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: []),
        ];
        final refreshedNotes = [
          Note(id: 1, content: 'Updated public note', isPrivate: false, userId: 1, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: []),
          Note(id: 2, content: 'New public note', isPrivate: false, userId: 2, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: []),
        ];

        // Setup initial discovery
        when(mockNotesService.latest(10, 1))
            .thenAnswer((_) async => NotesResult(initialNotes, 1));
        await discoveryProvider.navigateToPage(1);
        expect(discoveryProvider.notes.length, equals(1));

        // Setup refresh with new data
        when(mockNotesService.latest(10, 1))
            .thenAnswer((_) async => NotesResult(refreshedNotes, 2));
        await discoveryProvider.refresh();

        // Verify refresh calls correct service method
        verify(mockNotesService.latest(10, 1)).called(2); // Initial + refresh
        expect(discoveryProvider.notes.length, equals(2));
        expect(discoveryProvider.notes.first.content, equals('Updated public note'));
      });

      test('should clear all discovery data', () async {
        final testNotes = [
          Note(id: 1, content: 'Public note', isPrivate: false, userId: 1, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: []),
        ];
        
        // Setup some state
        when(mockNotesService.latest(10, 1))
            .thenAnswer((_) async => NotesResult(testNotes, 1));
        await discoveryProvider.navigateToPage(1);
        expect(discoveryProvider.notes.isNotEmpty, isTrue);

        // Clear all data (inherited from NoteListProvider)
        discoveryProvider.clearAllData();

        expect(discoveryProvider.notes, isEmpty);
        expect(discoveryProvider.currentPage, equals(1));
        expect(discoveryProvider.totalPages, equals(1));
        expect(discoveryProvider.isLoading, isFalse);
        expect(discoveryProvider.error, isNull);
        expect(discoveryProvider.groupedNotes, isEmpty);
      });
    });

    group('AuthAwareProvider integration', () {
      test('should inherit authentication-aware functionality', () {
        // Verify inheritance from NoteListProvider -> AuthAwareProvider
        expect(discoveryProvider.isAuthStateInitialized, isFalse);
        
        // Should have inherited methods available
        expect(() => discoveryProvider.clearAllData(), returnsNormally);
      });
    });
  });
}