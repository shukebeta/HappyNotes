import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl {
    // Get base URL based on environment
    return dotenv.env['BASE_URL'] ?? 'https://staging.dev.shukebeta.com';
  }
}