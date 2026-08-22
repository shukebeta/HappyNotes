import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:happy_notes/apis/ember_user_account_api.dart';
import 'package:happy_notes/entities/ember_user_account.dart';
import 'package:happy_notes/screens/settings/ember_sync_settings.dart';
import 'package:happy_notes/screens/settings/ember_sync_settings_controller.dart';
import 'package:happy_notes/services/ember_user_account_service.dart';

import '../test_helpers/seq_logger_setup.dart';

class FailingEmberService extends EmberUserAccountService {
  FailingEmberService()
      : super(
          emberUserAccountApi: EmberUserAccountApi(dio: Dio()),
        );

  int? testedAccountId;

  @override
  Future<bool> test(int accountId) async {
    testedAccountId = accountId;
    throw Exception('offline');
  }
}

class StubEmberListController extends EmberSyncSettingsController {
  StubEmberListController(FailingEmberService service) : super(emberUserAccountService: service) {
    emberAccounts = const [
      EmberUserAccount(
        id: 42,
        userId: 5,
        emberUrl: 'https://ember.example',
        apiKey: '****',
        status: 'Normal',
      ),
    ];
  }

  @override
  Future<bool> load(BuildContext context) async => true;
}

void main() {
  late StubEmberListController controller;
  late FailingEmberService service;

  setUp(() async {
    setupSeqLoggerForTesting();
    await GetIt.instance.reset();
    service = FailingEmberService();
    controller = StubEmberListController(service);
    GetIt.instance.registerSingleton<EmberSyncSettingsController>(controller);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  testWidgets('lists account status and required actions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: EmberSyncSettings()));
    await tester.pumpAndSettle();

    expect(find.text('https://ember.example'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Disable'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Test'));
    await tester.pump();
    expect(service.testedAccountId, 42);
    expect(find.textContaining('Ember connection test failed'), findsOneWidget);
  });
}
