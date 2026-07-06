import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/dependency_injection.dart' as di;
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/providers/linked_notes_provider.dart';
import 'package:happy_notes/providers/notes_provider.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/services/note_update_coordinator.dart';
import 'package:happy_notes/services/notes_services.dart';
import 'package:provider/provider.dart';

import '../test_helpers/fake_notes_dio.dart';
import '../test_helpers/seq_logger_setup.dart';

class _NoopNoteUpdateCoordinator implements NoteUpdateCoordinator {
  int notifyCalls = 0;

  @override
  void notifyNoteUpdated(Note updatedNote) {
    notifyCalls++;
  }
}

Note _testNote({String content = 'original content'}) => Note(
      id: 42,
      userId: 7,
      content: content,
      isPrivate: false,
      isLong: false,
      isMarkdown: false,
      createdAt: 1700000000,
    );

Map<String, dynamic> _noteJson(Note note) => {
      'id': note.id,
      'userId': note.userId,
      'content': note.content,
      'isPrivate': note.isPrivate,
      'isLong': note.isLong,
      'isMarkdown': note.isMarkdown,
      'createdAt': note.createdAt,
      'deletedAt': null,
    };

void main() {
  // DioClient caches the resolved Dio in a static field on first use, so the
  // same FakeNotesDio instance must be reused for every test in this file —
  // registering a fresh one per test would be silently ignored after test 1.
  final fakeDio = FakeNotesDio();
  late _NoopNoteUpdateCoordinator coordinator;

  setUp(() async {
    setupSeqLoggerForTesting();
    await dotenv.load(fileName: '.env');
    await GetIt.instance.reset();
    di.init();

    GetIt.instance.registerSingleton<Dio>(fakeDio);

    coordinator = _NoopNoteUpdateCoordinator();
    GetIt.instance.registerSingleton<NoteUpdateCoordinator>(coordinator);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Future<void> pumpNoteDetail(WidgetTester tester, Note note) async {
    fakeDio.getResponse = {'successful': true, 'data': _noteJson(note)};

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<NotesProvider>.value(
            value: NotesProvider(GetIt.instance<NotesService>()),
          ),
          ChangeNotifierProvider<LinkedNotesProvider>(
            create: (_) => LinkedNotesProvider(GetIt.instance<NotesService>()),
          ),
        ],
        child: MaterialApp(
          home: NoteDetail(note: note, enterEditing: true, fromDetailPage: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('save flow shows success and notifies the coordinator when update returns a note',
      (tester) async {
    final note = _testNote();
    final updated = _testNote(content: 'updated content');
    fakeDio.putResponse = {'successful': true, 'data': _noteJson(updated)};

    await pumpNoteDetail(tester, note);
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text('Note successfully updated.'), findsOneWidget);
    expect(coordinator.notifyCalls, 1);
  });

  testWidgets('save flow shows success without notifying the coordinator on a quiet duplicate',
      (tester) async {
    final note = _testNote();
    fakeDio.putResponse = {'successful': false, 'errorCode': AppConfig.quietErrorCode};

    await pumpNoteDetail(tester, note);
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(find.text('Note successfully updated.'), findsOneWidget);
    expect(coordinator.notifyCalls, 0);
  });
}
