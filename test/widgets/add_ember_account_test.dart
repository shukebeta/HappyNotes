import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:happy_notes/apis/ember_user_account_api.dart';
import 'package:happy_notes/screens/settings/add_ember_account.dart';
import 'package:happy_notes/screens/settings/ember_sync_settings_controller.dart';
import 'package:happy_notes/services/ember_user_account_service.dart';

import '../test_helpers/seq_logger_setup.dart';

class StubEmberSyncSettingsController extends EmberSyncSettingsController {
  StubEmberSyncSettingsController()
      : super(
          emberUserAccountService: EmberUserAccountService(
            emberUserAccountApi: EmberUserAccountApi(dio: Dio()),
          ),
        );

  String? addedUrl;
  String? addedApiKey;

  @override
  Future<bool> add(BuildContext context, String emberUrl, String apiKey) async {
    addedUrl = emberUrl;
    addedApiKey = apiKey;
    return true;
  }
}

void main() {
  late StubEmberSyncSettingsController controller;

  setUp(() async {
    setupSeqLoggerForTesting();
    await GetIt.instance.reset();
    controller = StubEmberSyncSettingsController();
    GetIt.instance.registerSingleton<EmberSyncSettingsController>(controller);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('API key field is obscured', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddEmberAccount()));

    final apiKeyField = find.widgetWithText(TextFormField, 'Ember API Key');
    final editableText = tester.widget<EditableText>(
      find.descendant(of: apiKeyField, matching: find.byType(EditableText)),
    );
    expect(editableText.obscureText, isTrue);
  });

  testWidgets('save normalizes the URL and submits credentials', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AddEmberAccount()));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ember URL'),
      'ember.example///',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ember API Key'),
      ' secret-key ',
    );

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(controller.addedUrl, 'https://ember.example');
    expect(controller.addedApiKey, 'secret-key');
  });

  testWidgets('required fields show validation messages', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddEmberAccount()));

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Ember URL is required'), findsOneWidget);
    expect(find.text('Ember API Key is required'), findsOneWidget);
  });
}
