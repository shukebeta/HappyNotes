import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get baseUrl {
    return dotenv.env['BASE_URL'] ?? 'https://staging.dev.shukebeta.com';
  }

  static int get pageSize {
    final pageSizeStr = dotenv.env['PAGE_SIZE'];
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
    final markdownIsEnabledStr = dotenv.env['MARKDOWN_IS_ENABLED'];
    return markdownIsEnabledStr == null || markdownIsEnabledStr == '1';
  }
}