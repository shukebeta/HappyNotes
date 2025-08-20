import 'package:happy_notes/services/seq_logger.dart';

/// Initialize SeqLogger for testing with network calls disabled
void setupSeqLoggerForTesting() {
  SeqLogger.initialize(enabled: false);
}
