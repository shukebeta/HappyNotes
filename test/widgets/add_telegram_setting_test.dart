import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:happy_notes/apis/telegram_settings_api.dart';
import 'package:happy_notes/entities/telegram_settings.dart';
import 'package:happy_notes/screens/settings/add_telegram_setting.dart';
import 'package:happy_notes/screens/settings/telegram_sync_settings_controller.dart';
import 'package:happy_notes/services/telegram_settings_service.dart';

import '../test_helpers/seq_logger_setup.dart';

/// Stub controller: records calls and never touches the network.
class StubTelegramSyncSettingsController extends TelegramSyncSettingsController {
  StubTelegramSyncSettingsController()
      : super(
          telegramSettingService:
              TelegramSettingsService(telegramSettingsApi: TelegramSettingsApi()),
        );

  bool addCalled = false;
  bool testCalled = false;
  bool testResult = true;

  @override
  Future<bool> addTelegramSetting(TelegramSettings setting) async {
    addCalled = true;
    return true;
  }

  @override
  Future<bool> testTelegramSetting(BuildContext context, TelegramSettings setting) async {
    testCalled = true;
    return testResult;
  }
}

void main() {
  late StubTelegramSyncSettingsController stub;

  setUp(() async {
    setupSeqLoggerForTesting();
    await GetIt.instance.reset();
    stub = StubTelegramSyncSettingsController();
    GetIt.instance.registerSingleton<TelegramSyncSettingsController>(stub);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  // Note: while the reminder dialog is open, _saveSetting is still awaiting it,
  // so the save-button spinner (CircularProgressIndicator) is still animating.
  // pumpAndSettle would time out on that perpetual animation — pump fixed
  // durations instead.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> fillAndSave(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddTelegramSetting()));
    await tester.enterText(find.widgetWithText(TextFormField, 'Channel ID'), '-100123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Channel Name'), 'My Channel');
    await tester.enterText(find.widgetWithText(TextFormField, 'Telegram Bot Token'), 'token');
    await tester.enterText(find.widgetWithText(TextFormField, 'Token Remark'), 'remark');
    await tester.tap(find.text('Save Settings'));
    await settle(tester);
  }

  testWidgets('save shows a non-blocking test reminder', (tester) async {
    await fillAndSave(tester);

    expect(stub.addCalled, isTrue);
    expect(find.text('Test now'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
  });

  testWidgets('choosing Later dismisses without testing', (tester) async {
    await fillAndSave(tester);

    await tester.tap(find.text('Later'));
    await settle(tester);

    expect(stub.testCalled, isFalse);
    // Dialog dismissed; the setting stays saved (save was never blocked).
    expect(find.text('Test now'), findsNothing);
  });

  testWidgets('choosing Test now runs the test flow', (tester) async {
    await fillAndSave(tester);

    await tester.tap(find.text('Test now'));
    await settle(tester);

    expect(stub.testCalled, isTrue);
    expect(find.text('Test now'), findsNothing);
  });
}
