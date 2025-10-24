import 'package:get_it/get_it.dart';
import 'seq_logger_setup.dart';

final getIt = GetIt.instance;

void setupTestServiceLocator() {
  // Initialize SeqLogger for tests with network calls disabled
  setupSeqLoggerForTesting();
}

void tearDownTestServiceLocator() {
  getIt.reset();
}
