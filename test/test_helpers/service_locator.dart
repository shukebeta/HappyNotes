import 'package:get_it/get_it.dart';
import 'package:happy_notes/utils/app_logger_interface.dart';
import 'package:mockito/mockito.dart';
import 'seq_logger_setup.dart';

class MockAppLogger extends Mock implements AppLoggerInterface {}

final getIt = GetIt.instance;

void setupTestServiceLocator() {
  // Initialize SeqLogger for tests with network calls disabled
  setupSeqLoggerForTesting();

  // Unregister if already registered to ensure a clean state
  if (getIt.isRegistered<AppLoggerInterface>()) {
    getIt.unregister<AppLoggerInterface>();
  }
  getIt.registerLazySingleton<AppLoggerInterface>(() => MockAppLogger());
}

void tearDownTestServiceLocator() {
  getIt.reset();
}
