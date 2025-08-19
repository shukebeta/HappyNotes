import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_notes/screens/account/user_session.dart';

import 'app_constants.dart';

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'https://staging-happynotes-api.dev.shukebeta.com';
  }

  static String get imgBaseUrl {
    return dotenv.env['IMG_BASE_URL'] ?? 'https://staging-happynotes-img.dev.shukebeta.com';
  }

  static String get uploaderBaseUrl {
    return dotenv.env['UPLOADER_BASE_URL'] ?? 'https://staging-happynotes-img-uploader.dev.shukebeta.com';
  }

  static String get seqServerUrl {
    return dotenv.env['SEQ_SERVER_URL'] ?? 'http://seq.shukebeta.eu.org:5341';
  }

  static String get seqApiKey {
    return dotenv.env['SEQ_API_KEY'] ?? '';
  }

  /// Returns the maximum dimension (width or height) for image processing.
  ///
  /// This value is used to determine the size limit for the longer side of an image.
  /// It's retrieved from the environment variable 'IMG_MAX_DIMENSION' or defaults to 1600.
  static int get imageMaxDimension {
    return int.parse(dotenv.env['IMG_MAX_DIMENSION'] ?? '1600');
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
    return fontFamily ?? 'Noto Sans';
  }

  static String get version {
    return dotenv.env['VERSION'] ?? 'version-place-holder';
  }

  static bool get debugging {
    return dotenv.env['DEBUGGING'] == '1';
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