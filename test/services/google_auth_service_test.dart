import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:happy_notes/services/google_auth_service.dart';

class FakeGoogleSignInPlatform extends GoogleSignInPlatform {
  GoogleSignInException? authenticateException;
  AuthenticationResults? authenticateResult;

  @override
  Future<void> init(InitParameters params) async {}

  @override
  Future<AuthenticationResults?>? attemptLightweightAuthentication(
    AttemptLightweightAuthenticationParameters params,
  ) => null;

  @override
  bool supportsAuthenticate() => true;

  @override
  Future<AuthenticationResults> authenticate(AuthenticateParameters params) async {
    final exception = authenticateException;
    if (exception != null) {
      throw exception;
    }
    return authenticateResult!;
  }

  @override
  bool authorizationRequiresUserInteraction() => false;

  @override
  Future<ClientAuthorizationTokenData?> clientAuthorizationTokensForScopes(
    ClientAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<ServerAuthorizationTokenData?> serverAuthorizationTokensForScopes(
    ServerAuthorizationTokensForScopesParameters params,
  ) async => null;

  @override
  Future<void> signOut(SignOutParams params) async {}

  @override
  Future<void> disconnect(DisconnectParams params) async {}
}

void main() {
  group('GoogleAuthService.signInWithButton', () {
    late FakeGoogleSignInPlatform fakePlatform;
    late GoogleAuthService service;

    setUp(() {
      fakePlatform = FakeGoogleSignInPlatform();
      GoogleSignInPlatform.instance = fakePlatform;
      service = GoogleAuthService();
    });

    test('returns the idToken on successful authentication', () async {
      fakePlatform.authenticateResult = const AuthenticationResults(
        user: GoogleSignInUserData(email: 'test@example.com', id: '123'),
        authenticationTokens: AuthenticationTokenData(idToken: 'a-real-id-token'),
      );

      final idToken = await service.signInWithButton();

      expect(idToken, 'a-real-id-token');
    });

    test('returns null when the user cancels', () async {
      fakePlatform.authenticateException = const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );

      final idToken = await service.signInWithButton();

      expect(idToken, isNull);
    });

    test('rethrows for non-cancel exceptions', () async {
      fakePlatform.authenticateException = const GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
        description: 'boom',
      );

      expect(() => service.signInWithButton(), throwsA(isA<GoogleSignInException>()));
    });
  });
}
