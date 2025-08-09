import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:happy_notes/providers/notes_provider.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';
import 'package:happy_notes/models/note_model.dart';
import 'package:happy_notes/exceptions/api_exception.dart';

import 'notes_provider_test.mocks.dart';

@GenerateMocks([NotesService])
void main() {
  group('NotesProvider', () {
    late NotesProvider provider;
    late MockNotesService mockNotesService;

    final mockNotes = [
      Note(
        id: 1,
        userId: 123,
        content: 'Test note 1',
        isPrivate: false,
        isMarkdown: false,
        isLong: false,
        createdAt: 1640995200000, // 2022-01-01 00:00:00
        deletedAt: null,
        user: null,
        tags: [],
      ),
      Note(
        id: 2,
        userId: 123,
        content: 'Test note 2',
        isPrivate: true,
        isMarkdown: false,
        isLong: false,
        createdAt: 1641081600000, // 2022-01-02 00:00:00
        deletedAt: null,
        user: null,
        tags: [],
      ),
    ];

    setUp(() {
      mockNotesService = MockNotesService();
      provider = NotesProvider(mockNotesService);
    });

    group('initial state', () {
      test('should have correct initial values', () {
        expect(provider.notes, isEmpty);
        expect(provider.groupedNotes, isEmpty);
        expect(provider.isLoadingList, false);
        expect(provider.isLoadingAdd, false);
        expect(provider.isRefreshing, false);
        expect(provider.listError, null);
        expect(provider.addError, null);
        expect(provider.canLoadMore, false);
      });
    });

    group('fetchNotes', () {
      test('should fetch notes successfully', () async {
        final mockResult = NotesResult(mockNotes, 2);
        when(mockNotesService.myLatest(any, any)).thenAnswer((_) async => mockResult);

        await provider.fetchNotes();

        expect(provider.notes, mockNotes);
        expect(provider.isLoadingList, false);
        expect(provider.listError, null);
        expect(provider.canLoadMore, false);
        expect(provider.groupedNotes.length, 2);
        verify(mockNotesService.myLatest(10, 1)).called(1);
      });

      test('should handle load more correctly', () async {
        // First load
        final firstResult = NotesResult([mockNotes[0]], 2);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => firstResult);
        await provider.fetchNotes();

        // Load more
        final secondResult = NotesResult([mockNotes[1]], 2);
        when(mockNotesService.myLatest(10, 2)).thenAnswer((_) async => secondResult);
        await provider.fetchNotes(loadMore: true);

        expect(provider.notes.length, 2);
        expect(provider.notes, mockNotes);
        expect(provider.canLoadMore, false);
        verify(mockNotesService.myLatest(10, 1)).called(1);
        verify(mockNotesService.myLatest(10, 2)).called(1);
      });

      test('should prevent multiple simultaneous loads', () async {
        final mockResult = NotesResult(mockNotes, 2);
        when(mockNotesService.myLatest(any, any)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return mockResult;
        });

        // Start multiple fetchNotes calls
        final future1 = provider.fetchNotes();
        final future2 = provider.fetchNotes();
        final future3 = provider.fetchNotes();

        await Future.wait([future1, future2, future3]);

        // Only one API call should have been made
        verify(mockNotesService.myLatest(10, 1)).called(1);
      });

      test('should not load more when canLoadMore is false', () async {
        final mockResult = NotesResult(mockNotes, 2);
        when(mockNotesService.myLatest(any, any)).thenAnswer((_) async => mockResult);

        await provider.fetchNotes();
        expect(provider.canLoadMore, false);

        await provider.fetchNotes(loadMore: true);

        // Only one call should have been made (initial load)
        verify(mockNotesService.myLatest(10, 1)).called(1);
      });

      test('should handle ApiException correctly', () async {
        final apiException = ApiException({'message': 'API Error'});
        when(mockNotesService.myLatest(any, any)).thenThrow(apiException);

        await provider.fetchNotes();

        expect(provider.notes, isEmpty);
        expect(provider.isLoadingList, false);
        expect(provider.listError, contains('API Error'));
      });

      test('should handle generic exception correctly', () async {
        when(mockNotesService.myLatest(any, any)).thenThrow(Exception('Network error'));

        await provider.fetchNotes();

        expect(provider.notes, isEmpty);
        expect(provider.isLoadingList, false);
        expect(provider.listError, contains('Network error'));
      });

      test('should group notes by date correctly', () async {
        final mockResult = NotesResult(mockNotes, 2);
        when(mockNotesService.myLatest(any, any)).thenAnswer((_) async => mockResult);

        await provider.fetchNotes();

        expect(provider.groupedNotes.length, 2);
        expect(provider.groupedNotes['2022-01-01']?.length, 1);
        expect(provider.groupedNotes['2022-01-02']?.length, 1);
        expect(provider.groupedNotes['2022-01-01']?.first.id, 1);
        expect(provider.groupedNotes['2022-01-02']?.first.id, 2);
      });
    });

    group('refreshNotes', () {
      test('should reset pagination and fetch fresh data', () async {
        final mockResult = NotesResult([mockNotes[0]], 1);
        when(mockNotesService.myLatest(any, any)).thenAnswer((_) async => mockResult);

        await provider.refreshNotes();

        expect(provider.notes.length, 1);
        expect(provider.groupedNotes.isNotEmpty, true);
        verify(mockNotesService.myLatest(10, 1)).called(1);
      });
    });

    group('addNote', () {
      final newNote = Note(
        id: 3,
        userId: 123,
        content: 'New test note',
        isPrivate: false,
        isMarkdown: false,
        isLong: false,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        deletedAt: null,
        user: null,
        tags: [],
      );

      test('should add note successfully', () async {
        when(mockNotesService.post(any)).thenAnswer((_) async => 3);
        when(mockNotesService.get(3)).thenAnswer((_) async => newNote);

        final result = await provider.addNote('New test note');

        expect(result, newNote);
        expect(provider.notes.first, newNote);
        expect(provider.isLoadingAdd, false);
        expect(provider.addError, null);
        verify(mockNotesService.post(any)).called(1);
        verify(mockNotesService.get(3)).called(1);
      });

      test('should prevent multiple simultaneous adds', () async {
        when(mockNotesService.post(any)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 3;
        });
        when(mockNotesService.get(3)).thenAnswer((_) async => newNote);

        // Start multiple addNote calls
        final future1 = provider.addNote('Test note 1');
        final future2 = provider.addNote('Test note 2');
        final future3 = provider.addNote('Test note 3');

        final results = await Future.wait([future1, future2, future3]);

        // Only the first call should have succeeded
        final nonNullResults = results.where((r) => r != null).length;
        expect(nonNullResults, 1);
        verify(mockNotesService.post(any)).called(1);
      });

      test('should handle ApiException in addNote', () async {
        final apiException = ApiException({'message': 'Add failed'});
        when(mockNotesService.post(any)).thenThrow(apiException);

        final result = await provider.addNote('Test note');

        expect(result, null);
        expect(provider.isLoadingAdd, false);
        expect(provider.addError, contains('Add failed'));
        expect(provider.notes, isEmpty);
      });

      test('should handle generic exception in addNote', () async {
        when(mockNotesService.post(any)).thenThrow(Exception('Network error'));

        final result = await provider.addNote('Test note');

        expect(result, null);
        expect(provider.isLoadingAdd, false);
        expect(provider.addError, contains('Network error'));
        expect(provider.notes, isEmpty);
      });

      test('should add note with custom parameters', () async {
        when(mockNotesService.post(any)).thenAnswer((_) async => 3);
        when(mockNotesService.get(3)).thenAnswer((_) async => newNote);

        await provider.addNote(
          'Private markdown note',
          isPrivate: true,
          isMarkdown: true,
          publishDateTime: '2022-01-01',
        );

        final capturedModel = verify(mockNotesService.post(captureAny)).captured.first as NoteModel;
        expect(capturedModel.content, 'Private markdown note');
        expect(capturedModel.isPrivate, true);
        expect(capturedModel.isMarkdown, true);
        expect(capturedModel.publishDateTime, '2022-01-01');
      });
    });

    group('updateNote', () {
      test('should update note successfully', () async {
        final existingNote = mockNotes[0];
        provider.notes.addAll([existingNote]);

        when(mockNotesService.update(1, 'Updated content', false, false))
            .thenAnswer((_) async => 1);

        final result = await provider.updateNote(1, 'Updated content');

        expect(result, true);
        expect(provider.notes.first.content, 'Updated content');
        verify(mockNotesService.update(1, 'Updated content', false, false)).called(1);
      });

      test('should return false when note not found', () async {
        final result = await provider.updateNote(999, 'Updated content');

        expect(result, false);
        verifyNever(mockNotesService.update(any, any, any, any));
      });

      test('should handle exception in updateNote', () async {
        final existingNote = mockNotes[0];
        provider.notes.addAll([existingNote]);

        when(mockNotesService.update(any, any, any, any))
            .thenThrow(Exception('Update failed'));

        final result = await provider.updateNote(1, 'Updated content');

        expect(result, false);
      });
    });

    group('deleteNote', () {
      test('should delete note successfully', () async {
        provider.notes.addAll(mockNotes);

        when(mockNotesService.delete(1)).thenAnswer((_) async => 1);

        final result = await provider.deleteNote(1);

        expect(result, true);
        expect(provider.notes.length, 1);
        expect(provider.notes.first.id, 2);
        verify(mockNotesService.delete(1)).called(1);
      });

      test('should handle exception in deleteNote', () async {
        provider.notes.addAll(mockNotes);

        when(mockNotesService.delete(1)).thenThrow(Exception('Delete failed'));

        final result = await provider.deleteNote(1);

        expect(result, false);
        expect(provider.notes.length, 2); // No change
      });
    });

    group('undeleteNote', () {
      test('should undelete note and refresh list', () async {
        final mockResult = NotesResult(mockNotes, 2);
        when(mockNotesService.undelete(1)).thenAnswer((_) async => 1);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => mockResult);

        final result = await provider.undeleteNote(1);

        expect(result, true);
        expect(provider.notes, mockNotes);
        verify(mockNotesService.undelete(1)).called(1);
        verify(mockNotesService.myLatest(10, 1)).called(1);
      });

      test('should handle exception in undeleteNote', () async {
        when(mockNotesService.undelete(1)).thenThrow(Exception('Undelete failed'));

        final result = await provider.undeleteNote(1);

        expect(result, false);
      });
    });

    group('getNote', () {
      test('should get single note successfully', () async {
        when(mockNotesService.get(1, includeDeleted: false))
            .thenAnswer((_) async => mockNotes[0]);

        final result = await provider.getNote(1);

        expect(result, mockNotes[0]);
        verify(mockNotesService.get(1, includeDeleted: false)).called(1);
      });

      test('should handle exception in getNote', () async {
        when(mockNotesService.get(1, includeDeleted: false))
            .thenThrow(Exception('Get failed'));

        final result = await provider.getNote(1);

        expect(result, null);
      });
    });

    group('searchNotes', () {
      test('should search notes successfully', () async {
        final mockResult = NotesResult([mockNotes[0]], 1);
        when(mockNotesService.searchNotes('test', 10, 1))
            .thenAnswer((_) async => mockResult);

        await provider.searchNotes('test');

        expect(provider.notes.length, 1);
        expect(provider.notes.first.id, 1);
        verify(mockNotesService.searchNotes('test', 10, 1)).called(1);
      });

      test('should handle load more in search', () async {
        // First search
        final firstResult = NotesResult([mockNotes[0]], 2);
        when(mockNotesService.searchNotes('test', 10, 1))
            .thenAnswer((_) async => firstResult);
        await provider.searchNotes('test');

        // Load more search results
        final secondResult = NotesResult([mockNotes[1]], 2);
        when(mockNotesService.searchNotes('test', 10, 2))
            .thenAnswer((_) async => secondResult);
        await provider.searchNotes('test', loadMore: true);

        expect(provider.notes.length, 2);
        verify(mockNotesService.searchNotes('test', 10, 1)).called(1);
        verify(mockNotesService.searchNotes('test', 10, 2)).called(1);
      });
    });

    group('fetchTagNotes', () {
      test('should fetch tag notes successfully', () async {
        final mockResult = NotesResult([mockNotes[0]], 1);
        when(mockNotesService.tagNotes('important', 10, 1))
            .thenAnswer((_) async => mockResult);

        await provider.fetchTagNotes('important');

        expect(provider.notes.length, 1);
        expect(provider.notes.first.id, 1);
        verify(mockNotesService.tagNotes('important', 10, 1)).called(1);
      });

      test('should handle load more in tag notes', () async {
        // First load
        final firstResult = NotesResult([mockNotes[0]], 2);
        when(mockNotesService.tagNotes('important', 10, 1))
            .thenAnswer((_) async => firstResult);
        await provider.fetchTagNotes('important');

        // Load more
        final secondResult = NotesResult([mockNotes[1]], 2);
        when(mockNotesService.tagNotes('important', 10, 2))
            .thenAnswer((_) async => secondResult);
        await provider.fetchTagNotes('important', loadMore: true);

        expect(provider.notes.length, 2);
        verify(mockNotesService.tagNotes('important', 10, 1)).called(1);
        verify(mockNotesService.tagNotes('important', 10, 2)).called(1);
      });
    });

    group('AuthAwareProvider behavior', () {
      test('should load data on login', () async {
        final mockResult = NotesResult(mockNotes, 2);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => mockResult);

        await provider.onLogin();

        expect(provider.notes, mockNotes);
        verify(mockNotesService.myLatest(10, 1)).called(1);
      });

      test('should clear all data on logout', () async {
        // Add some data first
        final mockResult = NotesResult(mockNotes, 2);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => mockResult);
        await provider.fetchNotes();
        expect(provider.notes.isNotEmpty, true);

        // Clear data
        provider.clearAllData();

        expect(provider.notes, isEmpty);
        expect(provider.groupedNotes, isEmpty);
        expect(provider.isLoadingList, false);
        expect(provider.isLoadingAdd, false);
        expect(provider.isRefreshing, false);
        expect(provider.listError, null);
        expect(provider.addError, null);
      });

      test('should handle auth state changes', () async {
        final mockResult = NotesResult(mockNotes, 2);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => mockResult);

        // Test login
        await provider.onAuthStateChanged(true);
        expect(provider.notes, mockNotes);
        expect(provider.isAuthStateInitialized, true);

        // Test logout
        await provider.onAuthStateChanged(false);
        expect(provider.notes, isEmpty);
        expect(provider.isAuthStateInitialized, false);
      });
    });

    group('listener notifications', () {
      test('should notify listeners on data changes', () async {
        bool notified = false;
        provider.addListener(() {
          notified = true;
        });

        final mockResult = NotesResult(mockNotes, 2);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => mockResult);

        await provider.fetchNotes();

        expect(notified, true);
      });
    });
  });
}