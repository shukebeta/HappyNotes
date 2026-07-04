import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:happy_notes/app_config.dart';

import 'google_signin_button_stub.dart' if (dart.library.js_interop) 'google_signin_button_web.dart';

/// Wraps `GoogleSignIn.instance` so it's the only seam in the app that talks
/// to the plugin directly, keeping the rest of the auth stack mockable.
class GoogleAuthService {
  Future<void>? _initFuture;

  /// `kIsWeb` short-circuits first so `Platform.isAndroid` is never evaluated
  /// on web, matching the existing guard in `main.dart`.
  bool get isAvailable => AppConfig.googleServerClientId.isNotEmpty && (kIsWeb || Platform.isAndroid);

  Future<void> _ensureInitialized() {
    // The web plugin asserts serverClientId == null (it isn't supported
    // there); Android instead requires serverClientId to obtain an idToken
    // usable by the backend, and ignores clientId.
    return _initFuture ??= GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? AppConfig.googleServerClientId : null,
      serverClientId: kIsWeb ? null : AppConfig.googleServerClientId,
    );
  }

  /// Android sign-in path: triggers the interactive picker and returns the
  /// resulting ID token, or null if the user canceled.
  Future<String?> signInWithButton() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  /// Web sign-in path: the GIS SDK owns the button UI, so this renders it
  /// once initialization resolves and reports the ID token via [onIdToken]
  /// when the resulting authentication event arrives.
  Widget buildWebSignInButton({required ValueChanged<String> onIdToken}) {
    return FutureBuilder<void>(
      future: _ensureInitialized(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done || snapshot.hasError) {
          return const SizedBox.shrink();
        }
        return googleSignInWebButton(onIdToken: onIdToken);
      },
    );
  }

  Future<void> signOut() async {
    if (_initFuture == null) {
      return;
    }
    await GoogleSignIn.instance.signOut();
  }
}
