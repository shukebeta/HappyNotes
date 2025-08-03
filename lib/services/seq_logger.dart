import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';
import '../app_config.dart';

class SeqLogger {
  static late Logger _logger;
  static late Dio _dio;
  static bool _isEnabled = true;
  
  static void initialize({bool enabled = true}) {
    _isEnabled = enabled;
    
    // Initialize Dio for Seq communication
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    
    // Set log level - more verbose in debug, warnings+ in production
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
    
    Logger.root.onRecord.listen((record) {
      // Always print to console in debug mode
      if (kDebugMode) {
        print('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
        if (record.error != null) print('Error: ${record.error}');
        if (record.stackTrace != null) print('Stack: ${record.stackTrace}');
      }
      
      // Always send to Seq (both debug and production)
      if (_isEnabled) {
        _sendToSeq(record);
      }
    });
    
    _logger = Logger('HappyNotes');
  }
  
  static Logger get logger => _logger;
  
  static Future<void> _sendToSeq(LogRecord record) async {
    try {
      final seqUrl = AppConfig.seqServerUrl;
      if (seqUrl.isEmpty) return; // Skip if no Seq server configured
      
      // Map Flutter log levels to Seq levels
      String seqLevel = 'Information';
      switch (record.level.name) {
        case 'FINE':
        case 'FINER':
        case 'FINEST':
          seqLevel = 'Debug';
          break;
        case 'INFO':
          seqLevel = 'Information';
          break;
        case 'WARNING':
          seqLevel = 'Warning';
          break;
        case 'SEVERE':
        case 'SHOUT':
          seqLevel = 'Error';
          break;
      }
      
      final payload = {
        '@t': record.time.toIso8601String(),
        '@l': seqLevel,
        '@m': record.message,
        'Logger': record.loggerName,
        'App': 'HappyNotes',
        'Platform': defaultTargetPlatform.name,
        'BuildMode': kDebugMode ? 'Debug' : (kProfileMode ? 'Profile' : 'Release'),
        if (record.error != null) 'Exception': record.error.toString(),
        if (record.stackTrace != null) 'StackTrace': record.stackTrace.toString(),
      };
      
      await _dio.post(
        '$seqUrl/api/events/raw?clef',
        data: payload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );
        
    } catch (e) {
      // Don't let logging errors break the app - only log to console in debug
      if (kDebugMode) {
        print('SeqLogger: Failed to send log to Seq: $e');
      }
    }
  }
  
  // Convenience methods
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info(message, error, stackTrace);
  }
  
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }
  
  static void severe(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }
  
  static void fine(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.fine(message, error, stackTrace);
  }
}