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
import '../test_helpers/service_locator.dart';

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
        createdAt: 1640995200, // 2022-01-01 00:00:00
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
        createdAt: 1641081600, // 2022-01-02 00:00:00
        deletedAt: null,
        user: null,
        tags: [],
      ),
    ];

    setUp(() {
      setupTestServiceLocator();
      mockNotesService = MockNotesService();
      provider = NotesProvider(mockNotesService);
    });

    tearDown(() {
      tearDownTestServiceLocator();
    });

    group('initial state', () {
      test('should have correct initial values', () {
        expect(provider.notes, isEmpty);
        expect(provider.groupedNotes, isEmpty);
        expect(provider.isLoadingList, false);
        expect(provider.isLoadingAdd, false);
        expect(provider.listError, null);
        expect(provider.addError, null);
        expect(provider.totalPages, 1);
      });
    });

    group('fetchNotes', () {
      test('should fetch notes successfully', () async {
        final mockResult = NotesResult(mockNotes, 20);
        when(mockNotesService.myLatest(any, any)).thenAnswer((_) async => mockResult);

        await provider.fetchNotesLegacy();

        expect(provider.notes, mockNotes);
        expect(provider.isLoadingList, false);
        expect(provider.listError, null);
        expect(provider.totalPages, 2);
        expect(provider.groupedNotes.length, 2);
        verify(mockNotesService.myLatest(10, 1)).called(1);
      });

      test('should handle page loading correctly', () async {
        // Load page 1
        final firstResult = NotesResult([mockNotes[0]], 20);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => firstResult);
        await provider.loadPage(1);

        expect(provider.notes.length, 1);
        expect(provider.notes, [mockNotes[0]]);
        expect(provider.currentPage, 1);
        expect(provider.totalPages, 2);

        // Load page 2
        final secondResult = NotesResult([mockNotes[1]], 20);
        when(mockNotesService.myLatest(10, 2)).thenAnswer((_) async => secondResult);
        await provider.loadPage(2);

        expect(provider.notes.length, 1);
        expect(provider.notes, [mockNotes[1]]);
        expect(provider.currentPage, 2);
        expect(provider.totalPages, 2);

        verify(mockNotesService.myLatest(10, 1)).called(1);
        verify(mockNotesService.myLatest(10, 2)).called(1);
      });

      test('should prevent multiple simultaneous loads', () async {
        final mockResult = NotesResult(mockNotes, 20);
        when(mockNotesService.myLatest(any, any)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return mockResult;
        });

        // Start multiple fetchNotes calls
        final future1 = provider.fetchNotesLegacy();
        final future2 = provider.fetchNotesLegacy();
        final future3 = provider.fetchNotesLegacy();

        await Future.wait([future1, future2, future3]);

        // Only one API call should have been made
        verify(mockNotesService.myLatest(10, 1)).called(1);
      });

      test('should not load invalid page numbers', () async {
        final mockResult = NotesResult(mockNotes, 20);
        when(mockNotesService.myLatest(any, any)).thenAnswer((_) async => mockResult);

        // Try to load page 0 (invalid)
        await provider.loadPage(0);

        // Try to load negative page (invalid)
        await provider.loadPage(-1);

        // Should not have made any API calls for invalid pages
        verifyNever(mockNotesService.myLatest(any, any));
      });

      test('should handle ApiException correctly', () async {
        final apiException = ApiException({'message': 'API Error'});
        when(mockNotesService.myLatest(any, any)).thenThrow(apiException);

        await provider.fetchNotesLegacy();

        expect(provider.notes, isEmpty);
        expect(provider.isLoadingList, false);
        expect(provider.listError, contains('API Error'));
      });

      test('should handle generic exception correctly', () async {
        when(mockNotesService.myLatest(any, any)).thenThrow(Exception('Network error'));

        await provider.fetchNotesLegacy();

        expect(provider.notes, isEmpty);
        expect(provider.isLoadingList, false);
        expect(provider.listError, contains('Network error'));
      });

      test('should group notes by date correctly', () async {
        final mockResult = NotesResult(mockNotes, 20);
        when(mockNotesService.myLatest(any, any)).thenAnswer((_) async => mockResult);

        await provider.fetchNotesLegacy();

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
        when(mockNotesService.post(any)).thenAnswer((_) async => newNote);

        final result = await provider.addNote('New test note');

        expect(result, newNote);
        expect(provider.notes.first, newNote);
        expect(provider.isLoadingAdd, false);
        expect(provider.addError, null);
        verify(mockNotesService.post(any)).called(1);
      });

      test('should prevent multiple simultaneous adds', () async {
        when(mockNotesService.post(any)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return newNote;
        });

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
        when(mockNotesService.post(any)).thenAnswer((_) async => newNote);

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


    group('deleteNote', () {
      test('should delete note successfully', () async {
        provider.notes.addAll(mockNotes);

        when(mockNotesService.delete(1)).thenAnswer((_) async => 1);

        final result = await provider.deleteNote(1);

        expect(result.isSuccess, isTrue);
        expect(provider.notes.length, 1);
        expect(provider.notes.first.id, 2);
        verify(mockNotesService.delete(1)).called(1);
      });

      test('should handle exception in deleteNote', () async {
        provider.notes.addAll(mockNotes);

        when(mockNotesService.delete(1)).thenThrow(Exception('Delete failed'));

        final result = await provider.deleteNote(1);

        expect(result.isSuccess, isFalse);
        expect(provider.notes.length, 2); // No change
      });
    });

    group('undeleteNote', () {
      test('should undelete note and refresh list', () async {
        final mockResult = NotesResult(mockNotes, 20);
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
        when(mockNotesService.get(1))
            .thenAnswer((_) async => mockNotes[0]);

        final result = await provider.getNote(1);

        expect(result, mockNotes[0]);
        verify(mockNotesService.get(1)).called(1);
      });

      test('should handle exception in getNote', () async {
        when(mockNotesService.get(1))
            .thenThrow(Exception('Get failed'));

        final result = await provider.getNote(1);

        expect(result, null);
      });
    });

    group('searchNotes', () {
      test('should clear cache and load page 1 (placeholder implementation)', () async {
        // Set up initial data
        final initialResult = NotesResult(mockNotes, 20);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => initialResult);
        await provider.loadPage(1);

        expect(provider.notes.length, 2);

        // Call searchNotes with placeholder implementation
        await provider.searchNotes('test');

        // Should clear cache and load page 1 again
        expect(provider.currentPage, 1);
        // Should have called myLatest twice (initial load + search clearing cache and reloading)
        verify(mockNotesService.myLatest(10, 1)).called(2);
      });
    });

    group('fetchTagNotes', () {
      test('should clear cache and load page 1 (placeholder implementation)', () async {
        // Set up initial data
        final initialResult = NotesResult(mockNotes, 20);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => initialResult);
        await provider.loadPage(1);

        expect(provider.notes.length, 2);

        // Call fetchTagNotes with placeholder implementation
        await provider.fetchTagNotes('important');

        // Should clear cache and load page 1 again
        expect(provider.currentPage, 1);
        // Should have called myLatest twice (initial load + tag search clearing cache and reloading)
        verify(mockNotesService.myLatest(10, 1)).called(2);
      });
    });

    group('AuthAwareProvider behavior', () {
      test('should load data on login', () async {
        final mockResult = NotesResult(mockNotes, 20);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => mockResult);

        await provider.onLogin();

        expect(provider.notes, mockNotes);
        verify(mockNotesService.myLatest(10, 1)).called(1);
      });

      test('should clear all data on logout', () async {
        // Add some data first
        final mockResult = NotesResult(mockNotes, 20);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => mockResult);
        await provider.fetchNotesLegacy();
        expect(provider.notes.isNotEmpty, true);

        // Clear data
        provider.clearNotesCache();

        expect(provider.notes, isEmpty);
        expect(provider.groupedNotes, isEmpty);
        expect(provider.isLoadingList, false);
        expect(provider.isLoadingAdd, false);
        expect(provider.listError, null);
        expect(provider.addError, null);
      });

      test('should handle auth state changes', () async {
        final mockResult = NotesResult(mockNotes, 20);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => mockResult);

        // Test login
        await provider.onAuthStateChanged(true);
        expect(provider.notes, mockNotes);
        expect(provider.isAuthStateInitialized, true);

        // Test logout
        await provider.onAuthStateChanged(false);
        provider.clearNotesCache(); // Ensure notes are cleared after logout
        // Notes should always be empty after logout/auth state change
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

        final mockResult = NotesResult(mockNotes, 20);
        when(mockNotesService.myLatest(10, 1)).thenAnswer((_) async => mockResult);

        await provider.fetchNotesLegacy();

        expect(notified, true);
      });
    });
  });
}
