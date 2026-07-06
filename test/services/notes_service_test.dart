import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/exceptions/api_exception.dart';
import 'package:happy_notes/services/notes_services.dart';

import '../test_helpers/fake_notes_dio.dart';
import '../test_helpers/seq_logger_setup.dart';

void main() {
  late FakeNotesDio fakeDio;
  late NotesService notesService;

  setUpAll(() {
    setupSeqLoggerForTesting();
    fakeDio = FakeNotesDio();
    GetIt.instance.registerSingleton<Dio>(fakeDio);
  });

  tearDownAll(() async {
    await GetIt.instance.reset();
  });

  setUp(() {
    notesService = NotesService();
    fakeDio.putResponse = null;
  });

  group('NotesService.update', () {
    test('returns the parsed Note when the API call succeeds', () async {
      fakeDio.putResponse = {
        'successful': true,
        'data': {
          'id': 42,
          'userId': 7,
          'content': 'updated content',
          'isPrivate': false,
          'isLong': false,
          'isMarkdown': false,
          'createdAt': 1700000000,
          'deletedAt': null,
        },
      };

      final result = await notesService.update(42, 'updated content', false, false);

      expect(result, isNotNull);
      expect(result!.id, 42);
      expect(result.content, 'updated content');
    });

    test('throws ApiException on a real API error', () async {
      fakeDio.putResponse = {
        'successful': false,
        'errorCode': AppConfig.quietErrorCode + 1,
        'errorMessage': 'Something went wrong',
      };

      expect(
        () => notesService.update(42, 'content', false, false),
        throwsA(isA<ApiException>()),
      );
    });

    test('returns null on the quiet duplicate error code', () async {
      fakeDio.putResponse = {
        'successful': false,
        'errorCode': AppConfig.quietErrorCode,
      };

      final result = await notesService.update(42, 'content', false, false);

      expect(result, isNull);
    });
  });
}
