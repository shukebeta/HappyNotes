import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_notes/screens/account/user_session.dart';

import 'app_constants.dart';

class AppConfig {
  AppConfig._();

  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? 'https://staging.dev.shukebeta.com';
  }

  static int get pageSize {
    final pageSizeStr = UserSession().settings(AppConstants.pageSize) ?? dotenv.env['PAGE_SIZE'];
    return pageSizeStr == null ? 20 : int.parse(pageSizeStr);
  }

  static bool get privateNoteOnlyIsEnabled {
    final privateNoteOnlyIsEnabledStr = UserSession().settings(AppConstants.privateNoteOnlyIsEnabled) ?? dotenv.env['PRIVATE_NOTE_ONLY'];
    return privateNoteOnlyIsEnabledStr != null && privateNoteOnlyIsEnabledStr == '1';
  }

  static bool get markdownIsEnabled {
    final markdownIsEnabledStr = UserSession().settings(AppConstants.markdownIsEnabled) ?? dotenv.env['MARKDOWN_IS_ENABLED'];
    return markdownIsEnabledStr != null && markdownIsEnabledStr == '1';
  }

  static bool get isIOSWeb {
    return kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }

  // duplicate request error, which shouldn't bother to show anything
  static int quietErrorCode = 105;

  static String get timezone {
    final timezone = UserSession().settings(AppConstants.timezone);
    return timezone ?? 'Pacific/Auckland';
  }

  static String get fontFamily {
    final fontFamily = UserSession().settings(AppConstants.fontFamily);
    return fontFamily ?? 'Varela';
  }

  // Map to store property access functions
  static final Map<String, dynamic Function()> _propertyAccessors = {
    AppConstants.baseUrl: () => baseUrl,
    AppConstants.pageSize: () => pageSize,
    AppConstants.markdownIsEnabled: () => markdownIsEnabled,
    AppConstants.privateNoteOnlyIsEnabled: () => privateNoteOnlyIsEnabled,
    AppConstants.quietErrorCode: () => quietErrorCode,
    AppConstants.timezone: () => timezone,
    AppConstants.fontFamily: () => fontFamily,
  };

  // Method to get property value by name
  static dynamic getProperty(String name) {
    final accessor = _propertyAccessors[name];
    if (accessor != null) {
      return accessor();
    } else {
      throw ArgumentError('No such property: $name');
    }
  }
}