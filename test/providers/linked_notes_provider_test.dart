import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/linked_notes_provider.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';

import 'notes_provider_test.mocks.dart';

void main() {
  group('LinkedNotesProvider Tests', () {
    late LinkedNotesProvider linkedNotesProvider;
    late MockNotesService mockNotesService;

    setUp(() {
      mockNotesService = MockNotesService();
      linkedNotesProvider = LinkedNotesProvider(mockNotesService);
    });

    group('Initialization', () {
      test('should initialize with empty state', () {
        expect(linkedNotesProvider.getLinkedNotes(1), isEmpty);
        expect(linkedNotesProvider.isLoading(1), isFalse);
        expect(linkedNotesProvider.getError(1), isNull);
      });

      test('should extend AuthAwareProvider', () {
        expect(linkedNotesProvider.isAuthStateInitialized, isFalse);
        expect(() => linkedNotesProvider.clearAllData(), returnsNormally);
      });
    });

    group('Data loading', () {
      test('should load linked notes successfully', () async {
        final parentNoteId = 123;
        final linkedNotes = [
          Note(id: 1, content: 'Linked note 1', isPrivate: false, userId: 1, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: ['@123']),
          Note(id: 2, content: 'Linked note 2', isPrivate: false, userId: 2, 
               isLong: false, isMarkdown: false, createdAt: 1640995100, 
               deletedAt: null, user: null, tags: ['@123']),
        ];
        final result = NotesResult(linkedNotes, 2);
        
        when(mockNotesService.getLinkedNotes(parentNoteId))
            .thenAnswer((_) async => result);

        await linkedNotesProvider.loadLinkedNotes(parentNoteId);

        verify(mockNotesService.getLinkedNotes(parentNoteId)).called(1);
        expect(linkedNotesProvider.getLinkedNotes(parentNoteId), equals(linkedNotes));
        expect(linkedNotesProvider.isLoading(parentNoteId), isFalse);
        expect(linkedNotesProvider.getError(parentNoteId), isNull);
      });

      test('should handle service errors during loading', () async {
        final parentNoteId = 123;
        
        when(mockNotesService.getLinkedNotes(parentNoteId))
            .thenThrow(Exception('Service unavailable'));

        await linkedNotesProvider.loadLinkedNotes(parentNoteId);

        verify(mockNotesService.getLinkedNotes(parentNoteId)).called(1);
        expect(linkedNotesProvider.getLinkedNotes(parentNoteId), isEmpty);
        expect(linkedNotesProvider.isLoading(parentNoteId), isFalse);
        expect(linkedNotesProvider.getError(parentNoteId), contains('Service unavailable'));
      });

      test('should prevent multiple simultaneous loads for same parent', () async {
        final parentNoteId = 123;
        
        // Setup a slow response
        when(mockNotesService.getLinkedNotes(parentNoteId))
            .thenAnswer((_) async {
              await Future.delayed(const Duration(milliseconds: 100));
              return NotesResult([], 0);
            });

        // Start first load
        final future1 = linkedNotesProvider.loadLinkedNotes(parentNoteId);
        expect(linkedNotesProvider.isLoading(parentNoteId), isTrue);
        
        // Try to start second load (should be ignored)
        await linkedNotesProvider.loadLinkedNotes(parentNoteId);
        
        // Wait for first load to complete
        await future1;

        // Should only have called service once
        verify(mockNotesService.getLinkedNotes(parentNoteId)).called(1);
      });

      test('should allow loading for different parent notes simultaneously', () async {
        final parentNoteId1 = 123;
        final parentNoteId2 = 456;
        
        when(mockNotesService.getLinkedNotes(parentNoteId1))
            .thenAnswer((_) async => NotesResult([], 0));
        when(mockNotesService.getLinkedNotes(parentNoteId2))
            .thenAnswer((_) async => NotesResult([], 0));

        await Future.wait([
          linkedNotesProvider.loadLinkedNotes(parentNoteId1),
          linkedNotesProvider.loadLinkedNotes(parentNoteId2),
        ]);

        verify(mockNotesService.getLinkedNotes(parentNoteId1)).called(1);
        verify(mockNotesService.getLinkedNotes(parentNoteId2)).called(1);
      });
    });

    group('Refresh functionality', () {
      test('should refresh linked notes by clearing cache first', () async {
        final parentNoteId = 123;
        final initialNotes = [
          Note(id: 1, content: 'Initial note', isPrivate: false, userId: 1, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: ['@123']),
        ];
        final refreshedNotes = [
          Note(id: 2, content: 'Refreshed note', isPrivate: false, userId: 1, 
               isLong: false, isMarkdown: false, createdAt: 1640995200, 
               deletedAt: null, user: null, tags: ['@123']),
        ];

        // Setup initial load
        when(mockNotesService.getLinkedNotes(parentNoteId))
            .thenAnswer((_) async => NotesResult(initialNotes, 1));
        await linkedNotesProvider.loadLinkedNotes(parentNoteId);
        expect(linkedNotesProvider.getLinkedNotes(parentNoteId), equals(initialNotes));

        // Setup refresh with different data
        when(mockNotesService.getLinkedNotes(parentNoteId))
            .thenAnswer((_) async => NotesResult(refreshedNotes, 1));
        await linkedNotesProvider.refreshLinkedNotes(parentNoteId);

        verify(mockNotesService.getLinkedNotes(parentNoteId)).called(2);
        expect(linkedNotesProvider.getLinkedNotes(parentNoteId), equals(refreshedNotes));
      });
    });

    group('Update functionality', () {
      test('should update linked note when tag is preserved', () async {
        final parentNoteId = 123;
        final originalNote = Note(id: 1, content: 'Original content', isPrivate: false, userId: 1, 
                                  isLong: false, isMarkdown: false, createdAt: 1640995200, 
                                  deletedAt: null, user: null, tags: ['@123']);
        final updatedNote = Note(id: 1, content: 'Updated content', isPrivate: false, userId: 1, 
                                 isLong: false, isMarkdown: false, createdAt: 1640995200, 
                                 deletedAt: null, user: null, tags: ['@123']);

        // Setup initial state
        when(mockNotesService.getLinkedNotes(parentNoteId))
            .thenAnswer((_) async => NotesResult([originalNote], 1));
        await linkedNotesProvider.loadLinkedNotes(parentNoteId);

        // Update the note
        linkedNotesProvider.updateLinkedNote(parentNoteId, updatedNote);

        final cachedNotes = linkedNotesProvider.getLinkedNotes(parentNoteId);
        expect(cachedNotes.length, equals(1));
        expect(cachedNotes.first.content, equals('Updated content'));
      });

      test('should remove linked note when tag is removed', () async {
        final parentNoteId = 123;
        final originalNote = Note(id: 1, content: 'Original content', isPrivate: false, userId: 1, 
                                  isLong: false, isMarkdown: false, createdAt: 1640995200, 
                                  deletedAt: null, user: null, tags: ['@123']);
        final updatedNote = Note(id: 1, content: 'Updated content', isPrivate: false, userId: 1, 
                                 isLong: false, isMarkdown: false, createdAt: 1640995200, 
                                 deletedAt: null, user: null, tags: ['other-tag']);

        // Setup initial state
        when(mockNotesService.getLinkedNotes(parentNoteId))
            .thenAnswer((_) async => NotesResult([originalNote], 1));
        await linkedNotesProvider.loadLinkedNotes(parentNoteId);

        // Update the note (without linking tag)
        linkedNotesProvider.updateLinkedNote(parentNoteId, updatedNote);

        expect(linkedNotesProvider.getLinkedNotes(parentNoteId), isEmpty);
      });

      test('should ignore update for non-existent note', () async {
        final parentNoteId = 123;
        final updatedNote = Note(id: 999, content: 'Non-existent note', isPrivate: false, userId: 1, 
                                 isLong: false, isMarkdown: false, createdAt: 1640995200, 
                                 deletedAt: null, user: null, tags: ['@123']);

        // No initial data loaded
        linkedNotesProvider.updateLinkedNote(parentNoteId, updatedNote);

        expect(linkedNotesProvider.getLinkedNotes(parentNoteId), isEmpty);
      });
    });

    group('Add functionality', () {
      test('should add new linked note with correct tag', () async {
        final parentNoteId = 123;
        final newNote = Note(id: 1, content: 'New linked note', isPrivate: false, userId: 1, 
                             isLong: false, isMarkdown: false, createdAt: 1640995200, 
                             deletedAt: null, user: null, tags: ['@123']);

        linkedNotesProvider.addLinkedNote(parentNoteId, newNote);

        final cachedNotes = linkedNotesProvider.getLinkedNotes(parentNoteId);
        expect(cachedNotes.length, equals(1));
        expect(cachedNotes.first, equals(newNote));
      });

      test('should ignore note without correct linking tag', () async {
        final parentNoteId = 123;
        final newNote = Note(id: 1, content: 'Unrelated note', isPrivate: false, userId: 1, 
                             isLong: false, isMarkdown: false, createdAt: 1640995200, 
                             deletedAt: null, user: null, tags: ['other-tag']);

        linkedNotesProvider.addLinkedNote(parentNoteId, newNote);

        expect(linkedNotesProvider.getLinkedNotes(parentNoteId), isEmpty);
      });

      test('should sort notes by creation date (newest first)', () async {
        final parentNoteId = 123;
        final olderNote = Note(id: 1, content: 'Older note', isPrivate: false, userId: 1, 
                               isLong: false, isMarkdown: false, createdAt: 1640995100, 
                               deletedAt: null, user: null, tags: ['@123']);
        final newerNote = Note(id: 2, content: 'Newer note', isPrivate: false, userId: 1, 
                               isLong: false, isMarkdown: false, createdAt: 1640995200, 
                               deletedAt: null, user: null, tags: ['@123']);

        linkedNotesProvider.addLinkedNote(parentNoteId, olderNote);
        linkedNotesProvider.addLinkedNote(parentNoteId, newerNote);

        final cachedNotes = linkedNotesProvider.getLinkedNotes(parentNoteId);
        expect(cachedNotes.length, equals(2));
        expect(cachedNotes.first.id, equals(2)); // Newer note first
        expect(cachedNotes.last.id, equals(1)); // Older note last
      });

      test('should prevent duplicate notes', () async {
        final parentNoteId = 123;
        final note = Note(id: 1, content: 'Note', isPrivate: false, userId: 1, 
                          isLong: false, isMarkdown: false, createdAt: 1640995200, 
                          deletedAt: null, user: null, tags: ['@123']);

        linkedNotesProvider.addLinkedNote(parentNoteId, note);
        linkedNotesProvider.addLinkedNote(parentNoteId, note); // Try to add again

        expect(linkedNotesProvider.getLinkedNotes(parentNoteId).length, equals(1));
      });
    });

    group('Remove functionality', () {
      test('should remove linked note by id', () async {
        final parentNoteId = 123;
        final note1 = Note(id: 1, content: 'Note 1', isPrivate: false, userId: 1, 
                           isLong: false, isMarkdown: false, createdAt: 1640995200, 
                           deletedAt: null, user: null, tags: ['@123']);
        final note2 = Note(id: 2, content: 'Note 2', isPrivate: false, userId: 1, 
                           isLong: false, isMarkdown: false, createdAt: 1640995200, 
                           deletedAt: null, user: null, tags: ['@123']);

        // Setup initial state
        when(mockNotesService.getLinkedNotes(parentNoteId))
            .thenAnswer((_) async => NotesResult([note1, note2], 2));
        await linkedNotesProvider.loadLinkedNotes(parentNoteId);

        // Remove one note
        linkedNotesProvider.removeLinkedNote(parentNoteId, 1);

        final cachedNotes = linkedNotesProvider.getLinkedNotes(parentNoteId);
        expect(cachedNotes.length, equals(1));
        expect(cachedNotes.first.id, equals(2));
      });

      test('should handle removal of non-existent note gracefully', () async {
        final parentNoteId = 123;
        
        linkedNotesProvider.removeLinkedNote(parentNoteId, 999);

        expect(linkedNotesProvider.getLinkedNotes(parentNoteId), isEmpty);
      });
    });

    group('State management', () {
      test('should clear all data correctly', () async {
        final parentNoteId1 = 123;
        final parentNoteId2 = 456;
        
        // Setup data for multiple parent notes
        when(mockNotesService.getLinkedNotes(parentNoteId1))
            .thenAnswer((_) async => NotesResult([
              Note(id: 1, content: 'Note 1', isPrivate: false, userId: 1, 
                   isLong: false, isMarkdown: false, createdAt: 1640995200, 
                   deletedAt: null, user: null, tags: ['@123']),
            ], 1));
        when(mockNotesService.getLinkedNotes(parentNoteId2))
            .thenThrow(Exception('Error'));

        await linkedNotesProvider.loadLinkedNotes(parentNoteId1);
        await linkedNotesProvider.loadLinkedNotes(parentNoteId2);

        // Verify data exists
        expect(linkedNotesProvider.getLinkedNotes(parentNoteId1).isNotEmpty, isTrue);
        expect(linkedNotesProvider.getError(parentNoteId2), isNotNull);

        // Clear all data
        linkedNotesProvider.clearAllData();

        expect(linkedNotesProvider.getLinkedNotes(parentNoteId1), isEmpty);
        expect(linkedNotesProvider.getLinkedNotes(parentNoteId2), isEmpty);
        expect(linkedNotesProvider.isLoading(parentNoteId1), isFalse);
        expect(linkedNotesProvider.isLoading(parentNoteId2), isFalse);
        expect(linkedNotesProvider.getError(parentNoteId1), isNull);
        expect(linkedNotesProvider.getError(parentNoteId2), isNull);
      });

      test('should manage independent state for different parent notes', () async {
        final parentNoteId1 = 123;
        final parentNoteId2 = 456;
        
        when(mockNotesService.getLinkedNotes(parentNoteId1))
            .thenAnswer((_) async => NotesResult([
              Note(id: 1, content: 'Note 1', isPrivate: false, userId: 1, 
                   isLong: false, isMarkdown: false, createdAt: 1640995200, 
                   deletedAt: null, user: null, tags: ['@123']),
            ], 1));
        when(mockNotesService.getLinkedNotes(parentNoteId2))
            .thenThrow(Exception('Service error'));

        await linkedNotesProvider.loadLinkedNotes(parentNoteId1);
        await linkedNotesProvider.loadLinkedNotes(parentNoteId2);

        // Verify independent states
        expect(linkedNotesProvider.getLinkedNotes(parentNoteId1).length, equals(1));
        expect(linkedNotesProvider.getLinkedNotes(parentNoteId2), isEmpty);
        expect(linkedNotesProvider.getError(parentNoteId1), isNull);
        expect(linkedNotesProvider.getError(parentNoteId2), contains('Service error'));
        expect(linkedNotesProvider.isLoading(parentNoteId1), isFalse);
        expect(linkedNotesProvider.isLoading(parentNoteId2), isFalse);
      });
    });
  });
}