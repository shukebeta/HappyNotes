import 'package:get_it/get_it.dart';
import 'seq_logger_setup.dart';
import 'package:happy_notes/screens/account/user_session.dart';
import 'package:happy_notes/entities/user_settings.dart';
import 'package:happy_notes/app_constants.dart';

final getIt = GetIt.instance;

void setupTestServiceLocator() {
  // Initialize SeqLogger for tests with network calls disabled
  setupSeqLoggerForTesting();

  // Ensure AppConfig.pageSize doesn't read from dotenv in tests by
  // providing a UserSession setting for pageSize. Many tests call
  // setupTestServiceLocator(), so this centralizes the workaround.
  UserSession().userSettings = [
    // Tests across the suite expect a page size of 10 by default.
    UserSettings(id: 1, userId: 0, settingName: AppConstants.pageSize, settingValue: '10')
  ];
}

void tearDownTestServiceLocator() {
  getIt.reset();
  // Clear session settings
  UserSession().userSettings = null;
}
