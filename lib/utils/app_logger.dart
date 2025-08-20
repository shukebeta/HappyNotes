import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'app_logger_interface.dart';

class AppLogger implements AppLoggerInterface {
  Logger? _logger;
  String? _logFilePath;

  AppLogger();

  @override
  Future<void> initialize() async {
    List<LogOutput> outputs = [ConsoleOutput()];

    // Only add file output for non-web platforms
    if (!kIsWeb) {
      _logFilePath = await _getLogFilePath();
      outputs.add(
        FileOutput(
          file: File(_logFilePath!),
          overrideExisting: false,
          encoding: utf8,
        ),
      );
    }

    _logger = Logger(
      printer: PrettyPrinter(),
      output: MultiOutput(outputs),
    );

    if (!kIsWeb) {
      i('Logger initialized at: $_logFilePath');
    } else {
      i('Logger initialized for web platform (console only)');
    }
  }

  @override
  void i(String message) {
    _logger?.i(message);
    if (!kIsWeb && _logFilePath != null) {
      _checkLogFileSize(_logFilePath!);
    }
  }

  @override
  void d(String message) {
    _logger?.d(message);
    if (!kIsWeb && _logFilePath != null) {
      _checkLogFileSize(_logFilePath!);
    }
  }

  @override
  void e(String message) {
    _logger?.e(message);
    if (!kIsWeb && _logFilePath != null) {
      _checkLogFileSize(_logFilePath!);
    }
  }

  Future<String> _getLogFilePath() async {
    try {
      final Directory directory = await getApplicationSupportDirectory();
      return '${directory.path}/dio_client.log';
    } catch (e) {
      return './dio_client.log';
    }
  }

  void _checkLogFileSize(String logFilePath) {
    final File logFile = File(logFilePath);
    const int maxFileSize = 10 * 1024 * 1024; // 10 MB
    if (logFile.lengthSync() > maxFileSize) {
      _truncateLogFile(logFile);
    }
  }

  void _truncateLogFile(File logFile) {
    final List<String> lines = logFile.readAsLinesSync();
    final int linesToRemove = lines.length ~/ 2; // Remove half of the lines
    final List<String> trimmedLines = lines.sublist(linesToRemove);
    logFile.writeAsStringSync(trimmedLines.join('\n'));
  }
}
