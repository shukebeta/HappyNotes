import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_notes/screens/account/user_session.dart';

import 'app_constants.dart';

class AppConfig {
  AppConfig._();

  // Safe accessor for dotenv environment map.
  // If flutter_dotenv wasn't initialized (tests or other contexts), access
  // to `dotenv.env` throws NotInitializedError. Return an empty map instead
  // so callers can gracefully fall back to defaults.
  static Map<String, String> get _env {
    try {
      return dotenv.env;
    } catch (e) {
      return const <String, String>{};
    }
  }

  static String get apiBaseUrl {
    return _env['API_BASE_URL'] ?? 'https://staging-happynotes-api.dev.shukebeta.com';
  }

  static String get imgBaseUrl {
    return _env['IMG_BASE_URL'] ?? 'https://staging-happynotes-img.dev.shukebeta.com';
  }

  static String get uploaderBaseUrl {
    return _env['UPLOADER_BASE_URL'] ?? 'https://staging-happynotes-img-uploader.dev.shukebeta.com';
  }

  static String get seqServerUrl {
    return _env['SEQ_SERVER_URL'] ?? 'http://seq.shukebeta.eu.org:5341';
  }

  static String get seqApiKey {
    return _env['SEQ_API_KEY'] ?? '';
  }

  /// Returns the maximum dimension (width or height) for image processing.
  ///
  /// This value is used to determine the size limit for the longer side of an image.
  /// It's retrieved from the environment variable 'IMG_MAX_DIMENSION' or defaults to 1600.
  static int get imageMaxDimension {
    return int.parse(_env['IMG_MAX_DIMENSION'] ?? '1600');
  }

  static int get pageSize {
    final pageSizeStr = UserSession().settings(AppConstants.pageSize) ?? _env['PAGE_SIZE'];
    if (pageSizeStr == null) return 10;
    try {
      return int.parse(pageSizeStr);
    } catch (e) {
      return 10;
    }
  }

  static bool get privateNoteOnlyIsEnabled {
    final privateNoteOnlyIsEnabledStr =
        UserSession().settings(AppConstants.privateNoteOnlyIsEnabled) ?? _env['PRIVATE_NOTE_ONLY'];
    return privateNoteOnlyIsEnabledStr != null && privateNoteOnlyIsEnabledStr == '1';
  }

  static bool get markdownIsEnabled {
    final markdownIsEnabledStr =
        UserSession().settings(AppConstants.markdownIsEnabled) ?? _env['MARKDOWN_IS_ENABLED'];
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
    return fontFamily ?? 'Noto Sans';
  }

  static String get version {
    return _env['VERSION'] ?? 'version-place-holder';
  }

  static bool get debugging {
    return _env['DEBUGGING'] == '1';
  }

  // Map to store property access functions
  static final Map<String, dynamic Function()> _propertyAccessors = {
    AppConstants.apiBaseUrl: () => apiBaseUrl,
    AppConstants.imgBaseUrl: () => imgBaseUrl,
    AppConstants.uploaderBaseUrl: () => uploaderBaseUrl,
    AppConstants.pageSize: () => pageSize,
    AppConstants.markdownIsEnabled: () => markdownIsEnabled,
    AppConstants.privateNoteOnlyIsEnabled: () => privateNoteOnlyIsEnabled,
    AppConstants.quietErrorCode: () => quietErrorCode,
    AppConstants.timezone: () => timezone,
    AppConstants.fontFamily: () => fontFamily,
    AppConstants.isIOSWeb: () => isIOSWeb,
    AppConstants.version: () => version,
    AppConstants.debugging: () => debugging,
    AppConstants.imageMaxDimension: () => imageMaxDimension,
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

  static String mastodonRedirectUri(String instanceUrl) {
    return '$apiBaseUrl/mastodonAuth/callback?instanceUrl=${Uri.encodeFull(instanceUrl)}';
  }
}
