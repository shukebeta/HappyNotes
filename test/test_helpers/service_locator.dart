import 'package:get_it/get_it.dart';
import 'seq_logger_setup.dart';
import 'package:happy_notes/screens/account/user_session.dart';
import 'package:happy_notes/entities/user_settings.dart';
import 'package:happy_notes/app_constants.dart';
import 'package:happy_notes/app_config.dart';

final getIt = GetIt.instance;

void setupTestServiceLocator() {
  // Initialize SeqLogger for tests with network calls disabled
  setupSeqLoggerForTesting();

  // Ensure AppConfig.pageSize doesn't read from dotenv in tests by
  // providing a UserSession setting for pageSize. Many tests call
  // setupTestServiceLocator(), so this centralizes the workaround.
  // Set test override for page size so tests can rely on pageSize=10 without
  // modifying production defaults. Keep UserSession fallback for tests that
  // explicitly read it as well.
  AppConfig.setConfigValue(AppConstants.pageSize, '10');
  UserSession().userSettings = [
    UserSettings(id: 1, userId: 0, settingName: AppConstants.pageSize, settingValue: '10')
  ];
}

void tearDownTestServiceLocator() {
  getIt.reset();
  // Clear session settings
  UserSession().userSettings = null;
  AppConfig.clearConfigOverrides();
}
