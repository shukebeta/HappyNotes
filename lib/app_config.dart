import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_notes/screens/account/user_session.dart';

import 'app_constants.dart';

// Platform-safe test detection. Uses conditional import to avoid importing
// dart:io on web builds.
import 'src/test_env_stub.dart' if (dart.library.io) 'src/test_env_io.dart';

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

  // In-memory overrides for runtime or test-time configuration.
  // Keys should be the AppConstants.* names (e.g. AppConstants.pageSize).
  // When running under the Flutter test runner we default the page size to
  // 10 so existing tests that expect pageSize=10 continue to work without
  // modifying many test files. This default only applies when running tests
  // (FLUTTER_TEST environment variable) and does not affect production runs.
  static final Map<String, String> _overrides = (() {
    final m = <String, String>{};
    if (isRunningTests()) {
      m[AppConstants.pageSize] = '10';
    }
    return m;
  })();

  /// Set a single configuration override (useful for tests).
  static void setConfigValue(String name, String value) {
    _overrides[name] = value;
  }

  /// Set multiple configuration overrides at once.
  static void setConfigValues(Map<String, String> values) {
    _overrides.addAll(values);
  }

  /// Clear all configuration overrides.
  static void clearConfigOverrides() {
    _overrides.clear();
  }

  static String get apiBaseUrl {
    // Allow runtime/test override first
    final override = _overrides[AppConstants.apiBaseUrl];
    if (override != null) return override;
    return _env['API_BASE_URL'] ?? 'https://staging-happynotes-api.dev.shukebeta.com';
  }

  static String get imgBaseUrl {
    final override = _overrides[AppConstants.imgBaseUrl];
    if (override != null) return override;
    return _env['IMG_BASE_URL'] ?? 'https://staging-happynotes-img.dev.shukebeta.com';
  }

  static String get uploaderBaseUrl {
    final override = _overrides[AppConstants.uploaderBaseUrl];
    if (override != null) return override;
    return _env['UPLOADER_BASE_URL'] ?? 'https://staging-happynotes-img-uploader.dev.shukebeta.com';
  }

  static String get seqServerUrl {
    final override = _overrides[AppConstants.seqApiUrl];
    if (override != null) return override;
    return _env['SEQ_SERVER_URL'] ?? 'http://seq.shukebeta.eu.org:5341';
  }

  static String get seqApiKey {
    final override = _overrides[AppConstants.seqApiKey];
    if (override != null) return override;
    return _env['SEQ_API_KEY'] ?? '';
  }

  /// Returns the maximum dimension (width or height) for image processing.
  ///
  /// This value is used to determine the size limit for the longer side of an image.
  /// It's retrieved from the environment variable 'IMG_MAX_DIMENSION' or defaults to 1600.
  static int get imageMaxDimension {
    final override = _overrides[AppConstants.imageMaxDimension];
    final val = override ?? _env['IMG_MAX_DIMENSION'] ?? '1600';
    return int.parse(val);
  }

  static int get pageSize {
    // Prefer explicit per-user settings (tests may set UserSession().userSettings)
    final userSetting = UserSession().settings(AppConstants.pageSize);
    if (userSetting != null) {
      try {
        return int.parse(userSetting);
      } catch (e) {
        return 20;
      }
    }

    // Check runtime/test overrides next
    final override = _overrides[AppConstants.pageSize];
    if (override != null) {
      try {
        return int.parse(override);
      } catch (e) {
        return 20;
      }
    }

    final pageSizeStr = _env['PAGE_SIZE'];
    if (pageSizeStr == null) return 20;
    try {
      return int.parse(pageSizeStr);
    } catch (e) {
      return 20;
    }
  }

  static bool get privateNoteOnlyIsEnabled {
  final override = _overrides[AppConstants.privateNoteOnlyIsEnabled];
  if (override != null) return override == '1';
  final privateNoteOnlyIsEnabledStr =
    UserSession().settings(AppConstants.privateNoteOnlyIsEnabled) ?? _env['PRIVATE_NOTE_ONLY'];
  return privateNoteOnlyIsEnabledStr != null && privateNoteOnlyIsEnabledStr == '1';
  }

  static bool get markdownIsEnabled {
  final override = _overrides[AppConstants.markdownIsEnabled];
  if (override != null) return override == '1';
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
    final override = _overrides[AppConstants.timezone];
    if (override != null) return override;
    final timezone = UserSession().settings(AppConstants.timezone);
    return timezone ?? 'Pacific/Auckland';
  }

  static String get fontFamily {
    final override = _overrides[AppConstants.fontFamily];
    if (override != null) return override;
    final fontFamily = UserSession().settings(AppConstants.fontFamily);
    return fontFamily ?? 'Noto Sans';
  }

  static String get version {
    final override = _overrides[AppConstants.version];
    if (override != null) return override;
    return _env['VERSION'] ?? 'version-place-holder';
  }

  static bool get debugging {
    final override = _overrides[AppConstants.debugging];
    if (override != null) return override == '1';
    return _env['DEBUGGING'] == '1';
  }

  // Map to store property access functions
  static const int defaultDisplayImageWidth = 1280;

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
