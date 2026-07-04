import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Web can't drive `GoogleSignIn.authenticate()` directly (the GIS SDK owns
/// the sign-in UI there), so the app embeds the platform-rendered button and
/// listens for the resulting authentication event instead.
Widget googleSignInWebButton({required ValueChanged<String> onIdToken}) {
  return _GoogleSignInWebButton(onIdToken: onIdToken);
}

class _GoogleSignInWebButton extends StatefulWidget {
  const _GoogleSignInWebButton({required this.onIdToken});

  final ValueChanged<String> onIdToken;

  @override
  State<_GoogleSignInWebButton> createState() => _GoogleSignInWebButtonState();
}

class _GoogleSignInWebButtonState extends State<_GoogleSignInWebButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = GoogleSignIn.instance.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        final idToken = event.user.authentication.idToken;
        if (idToken != null) {
          widget.onIdToken(idToken);
        }
      }
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return web.renderButton();
  }
}
