import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_notes/screens/account/user_session.dart';

class AppConfig {
  AppConfig._();

  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? 'https://staging.dev.shukebeta.com';
  }

  static int get pageSize {
    final pageSizeStr = UserSession().settings('pageSize') ?? dotenv.env['PAGE_SIZE'];
    return pageSizeStr == null ? 20 : int.parse(pageSizeStr);
  }

  static bool get pagerIsFixed {
    final pagerIsFixedStr = dotenv.env['PAGER_IS_FIXED'];
    return pagerIsFixedStr == null || pagerIsFixedStr == '1';
  }

  static bool get newNoteIsPublic {
    final newNoteIsPublicStr = dotenv.env['NEW_NOTE_IS_PUBLIC'];
    return newNoteIsPublicStr == null || newNoteIsPublicStr == '1';
  }

  static bool get markdownIsEnabled {
    final markdownIsEnabledStr = UserSession().settings('markdownIsEnabled') ?? dotenv.env['MARKDOWN_IS_ENABLED'];
    return markdownIsEnabledStr == null || markdownIsEnabledStr == '1';
  }

  // duplicate request error, which shouldn't bother to show anything
  static int get errorCodeQuiet => 105;

  static String get timezone {
    final timezone = UserSession().settings('timezone');
    return timezone ?? 'Pacific/Auckland';
  }

  // Map to store property access functions
  static final Map<String, dynamic Function()> _propertyAccessors = {
    'baseUrl': () => baseUrl,
    'pageSize': () => pageSize,
    'pagerIsFixed': () => pagerIsFixed,
    'newNoteIsPublic': () => newNoteIsPublic,
    'markdownIsEnabled': () => markdownIsEnabled,
    'errorCodeQuiet': () => errorCodeQuiet,
    'timezone': () => timezone,
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