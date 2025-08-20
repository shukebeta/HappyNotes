import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/entities/user.dart';
import 'package:happy_notes/screens/components/note_list/note_list.dart';
import 'package:happy_notes/screens/components/note_list/note_list_item.dart';

void main() {
  group('NoteListItem Tests', () {
    late Note testNote;

    setUp(() {
      testNote = Note(
        id: 1,
        userId: 1,
        content: 'Test note content',
        isPrivate: false,
        isMarkdown: false,
        isLong: false,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        deletedAt: null,
        user: User(
          username: 'testuser',
          email: 'test@example.com',
          gravatar: 'test-avatar',
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        ),
        tags: [],
      );
    });

    group('Dismissible Tests', () {
      testWidgets('should use Dismissible when dismissible enabled', (tester) async {        
        final widget = MaterialApp(
          home: Scaffold(
            body: NoteListItem(
              note: testNote,
              callbacks: ListItemCallbacks<Note>(
                onDelete: (note) {},
              ),
              config: const ListItemConfig(enableDismiss: true),
            ),
          ),
        );

        await tester.pumpWidget(widget);

        expect(find.byType(Dismissible), findsOneWidget);
      });

      testWidgets('should have correct dismissible configuration', (tester) async {
        final widget = MaterialApp(
          home: Scaffold(
            body: NoteListItem(
              note: testNote,
              callbacks: ListItemCallbacks<Note>(
                onDelete: (note) {},
              ),
              config: const ListItemConfig(enableDismiss: true),
            ),
          ),
        );

        await tester.pumpWidget(widget);

        final dismissible = tester.widget<Dismissible>(find.byType(Dismissible));
        
        expect(dismissible.direction, equals(DismissDirection.endToStart));
        expect(dismissible.key, equals(Key(testNote.id.toString())));
        expect(dismissible.dragStartBehavior, equals(DragStartBehavior.down));
      });
    });

    group('Configuration Tests', () {
      testWidgets('should not enable gestures when enableDismiss is false', (tester) async {
        final widget = MaterialApp(
          home: Scaffold(
            body: NoteListItem(
              note: testNote,
              callbacks: ListItemCallbacks<Note>(
                onDelete: (note) {},
              ),
              config: const ListItemConfig(enableDismiss: false), // Disabled
            ),
          ),
        );

        await tester.pumpWidget(widget);

        // Should not find Dismissible when disabled
        expect(find.byType(Dismissible), findsNothing);
      });

      testWidgets('should not enable gestures when onDelete callback is null', (tester) async {
        final widget = MaterialApp(
          home: Scaffold(
            body: NoteListItem(
              note: testNote,
              callbacks: const ListItemCallbacks<Note>(), // No onDelete callback
              config: const ListItemConfig(enableDismiss: true),
            ),
          ),
        );

        await tester.pumpWidget(widget);

        // Should not find Dismissible when no delete callback
        expect(find.byType(Dismissible), findsNothing);
      });
    });

    group('Integration Tests', () {
      testWidgets('should render note content correctly', (tester) async {
        final widget = MaterialApp(
          home: Scaffold(
            body: NoteListItem(
              note: testNote,
              callbacks: ListItemCallbacks<Note>(
                onTap: (note) {},
                onDelete: (note) {},
              ),
              config: const ListItemConfig(enableDismiss: true),
            ),
          ),
        );

        await tester.pumpWidget(widget);

        // Verify note content is displayed
        expect(find.text('Test note content'), findsOneWidget);
        expect(find.byType(NoteListItem), findsOneWidget);
      });
    });
  });
}