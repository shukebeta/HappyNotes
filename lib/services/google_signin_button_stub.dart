import 'package:flutter/widgets.dart';

/// Non-web fallback: the platform-controlled GIS button widget only exists
/// on web, so there is nothing to render on other platforms.
Widget googleSignInWebButton({required ValueChanged<String> onIdToken}) {
  return const SizedBox.shrink();
}
