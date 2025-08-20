import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:happy_notes/screens/new_note/new_note_controller.dart';
import 'package:happy_notes/models/note_model.dart';
import 'package:happy_notes/models/save_note_result.dart';
import 'package:happy_notes/providers/notes_provider.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/entities/user.dart';

@GenerateMocks([NotesProvider])
import 'new_note_controller_test.mocks.dart';

void main() {
  group('NewNoteController', () {
    late NewNoteController controller;
    late MockNotesProvider mockNotesProvider;
    late NoteModel noteModel;

    setUp(() {
      controller = NewNoteController();
      mockNotesProvider = MockNotesProvider();
      noteModel = NoteModel();
    });

    group('saveNoteAsync', () {
      test('should return validation error when content is empty', () async {
        // Arrange
        noteModel.content = '';

        // Act
        final result = await controller.saveNoteAsync(noteModel, mockNotesProvider);

        // Assert
        expect(result, isA<SaveNoteValidationError>());
        expect((result as SaveNoteValidationError).message, 'Please write something');
        verifyNever(mockNotesProvider.addNote(any, isPrivate: anyNamed('isPrivate')));
      });

      test('should return validation error when content is only whitespace', () async {
        // Arrange
        noteModel.content = '   \n\t  ';

        // Act
        final result = await controller.saveNoteAsync(noteModel, mockNotesProvider);

        // Assert
        expect(result, isA<SaveNoteValidationError>());
        expect((result as SaveNoteValidationError).message, 'Please write something');
      });

      test('should return success with pop action when note is saved successfully', () async {
        // Arrange
        final mockNote = Note(
          id: 1,
          userId: 1,
          content: 'Test note',
          isPrivate: false,
          isMarkdown: false,
          isLong: false,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          deletedAt: null,
        );
        mockNote.user = User(
          username: 'testuser',
          email: 'test@example.com',
          gravatar: '',
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
        mockNote.tags = [];

        noteModel.content = 'Test note';
        noteModel.isPrivate = false;
        noteModel.isMarkdown = false;

        when(mockNotesProvider.addNote(
          any,
          isPrivate: anyNamed('isPrivate'),
          isMarkdown: anyNamed('isMarkdown'),
          publishDateTime: anyNamed('publishDateTime'),
        )).thenAnswer((_) async => mockNote);

        // Act
        final result = await controller.saveNoteAsync(noteModel, mockNotesProvider);

        // Assert
        expect(result, isA<SaveNoteSuccess>());
        final success = result as SaveNoteSuccess;
        expect(success.savedNote, equals(mockNote));
        expect(success.action, SaveNoteAction.popWithNote);

        // Verify note model is cleared
        expect(noteModel.content, isEmpty);
        expect(noteModel.initialContent, '# '); // NoteModel adds prefix

        // Verify service call
        verify(mockNotesProvider.addNote(
          'Test note',
          isPrivate: false,
          isMarkdown: false,
          publishDateTime: '',
        )).called(1);
      });

      test('should return success with callback action when useCallback is true', () async {
        // Arrange
        final mockNote = Note(
          id: 1,
          userId: 1,
          content: 'Test note',
          isPrivate: true,
          isMarkdown: true,
          isLong: false,
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          deletedAt: null,
        );
        mockNote.user = User(
          username: 'testuser',
          email: 'test@example.com',
          gravatar: '',
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );
        mockNote.tags = [];

        noteModel.content = 'Test note';
        noteModel.isPrivate = true;
        noteModel.isMarkdown = true;

        when(mockNotesProvider.addNote(
          any,
          isPrivate: anyNamed('isPrivate'),
          isMarkdown: anyNamed('isMarkdown'),
          publishDateTime: anyNamed('publishDateTime'),
        )).thenAnswer((_) async => mockNote);

        // Act
        final result = await controller.saveNoteAsync(
          noteModel,
          mockNotesProvider,
          useCallback: true,
        );

        // Assert
        expect(result, isA<SaveNoteSuccess>());
        final success = result as SaveNoteSuccess;
        expect(success.savedNote, equals(mockNote));
        expect(success.action, SaveNoteAction.executeCallback);
      });

      test('should return service error when addNote returns null', () async {
        // Arrange
        noteModel.content = 'Test note';
        when(mockNotesProvider.addNote(any,
                isPrivate: anyNamed('isPrivate'),
                isMarkdown: anyNamed('isMarkdown'),
                publishDateTime: anyNamed('publishDateTime')))
            .thenAnswer((_) async => null);
        when(mockNotesProvider.addError).thenReturn('Network error');

        // Act
        final result = await controller.saveNoteAsync(noteModel, mockNotesProvider);

        // Assert
        expect(result, isA<SaveNoteServiceError>());
        expect((result as SaveNoteServiceError).message, 'Network error');
      });

      test('should return service error when addNote throws exception', () async {
        // Arrange
        noteModel.content = 'Test note';
        when(mockNotesProvider.addNote(any,
                isPrivate: anyNamed('isPrivate'),
                isMarkdown: anyNamed('isMarkdown'),
                publishDateTime: anyNamed('publishDateTime')))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await controller.saveNoteAsync(noteModel, mockNotesProvider);

        // Assert
        expect(result, isA<SaveNoteServiceError>());
        expect((result as SaveNoteServiceError).message, contains('Database error'));
      });
    });

    group('handlePopAsync', () {
      test('should return prevent when didPop is true', () {
        // Act
        final result = controller.handlePopAsync(noteModel, true);

        // Assert
        expect(result, isA<PopHandlerPrevent>());
      });

      test('should return allow when content is empty', () {
        // Arrange
        noteModel.content = '';

        // Act
        final result = controller.handlePopAsync(noteModel, false);

        // Assert
        expect(result, isA<PopHandlerAllow>());
      });

      test('should return allow when content matches initial content pattern', () {
        // Arrange
        noteModel.initialContent = 'initial'; // This becomes '#initial '
        noteModel.content = '#initial '; // User hasn't changed the initial content

        // Act
        final result = controller.handlePopAsync(noteModel, false);

        // Assert
        expect(result, isA<PopHandlerAllow>());
      });

      test('should return show dialog when content has unsaved changes', () {
        // Arrange
        noteModel.initialContent = 'initial'; // This becomes '#initial '
        noteModel.content = 'modified content';

        // Act
        final result = controller.handlePopAsync(noteModel, false);

        // Assert
        expect(result, isA<PopHandlerShowDialog>());
        final showDialog = result as PopHandlerShowDialog;
        expect(showDialog.content, 'modified content');
        expect(showDialog.initialContent, '#initial '); // Matches what setter creates
      });
    });
  });
}
