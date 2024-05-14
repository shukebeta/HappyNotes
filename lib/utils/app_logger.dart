import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(),
    output: MultiOutput([
      ConsoleOutput(),
      FileOutput(
        file: File(_logFilePath),
        overrideExisting: false,
        encoding: utf8,
      ),
    ]),
  );

  static late String _logFilePath; // Declare _logFilePath as late

  static void initialize() async {
    _logFilePath = await _getLogFilePath();
    i(_logFilePath);
  }

  static void i(String message) {
    _logger.i(message);
    _checkLogFileSize(_logFilePath);
  }

  static void d(String message) {
    _logger.d(message);
    _checkLogFileSize(_logFilePath);
  }

  static void e(String message) {
    _logger.e(message);
    _checkLogFileSize(_logFilePath);
  }

  static Future<String> _getLogFilePath() async {
    final Directory directory = await getApplicationSupportDirectory();
    return '${directory.path}/dio_client.log';
  }

  static void _checkLogFileSize(String logFilePath) {
    final File logFile = File(logFilePath);
    const int maxFileSize = 10 * 1024 * 1024; // 10 MB
    if (logFile.lengthSync() > maxFileSize) {
      _truncateLogFile(logFile);
    }
  }

  static void _truncateLogFile(File logFile) {
    final List<String> lines = logFile.readAsLinesSync();
    final int linesToRemove = lines.length ~/ 2; // Remove half of the lines
    final List<String> trimmedLines = lines.sublist(linesToRemove);
    logFile.writeAsStringSync(trimmedLines.join('\n'));
  }
}
