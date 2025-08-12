import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:happy_notes/providers/auth_provider.dart';
import 'package:happy_notes/services/account_service.dart';
import 'package:happy_notes/screens/account/user_session.dart';
import 'package:get_it/get_it.dart';

import 'auth_provider_test.mocks.dart';

@GenerateMocks([AccountService])
void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;
    late MockAccountService mockAccountService;

    setUp(() {
      mockAccountService = MockAccountService();

      // Reset GetIt and register fresh mock
      if (GetIt.instance.isRegistered<AccountService>()) {
        GetIt.instance.unregister<AccountService>();
      }
      GetIt.instance.registerSingleton<AccountService>(mockAccountService);

      // Clear UserSession
      UserSession().id = null;
      UserSession().email = null;
      UserSession().userSettings = null;
    });

    tearDown(() {
      if (GetIt.instance.isRegistered<AccountService>()) {
        GetIt.instance.unregister<AccountService>();
      }
    });

    test('initial state should be correct', () async {
      when(mockAccountService.getToken()).thenAnswer((_) async => null);
      authProvider = AuthProvider();

      expect(authProvider.token, null);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.isLoading, true); // Loading during initialization
      expect(authProvider.error, null);
      expect(authProvider.isInitialized, false);

      // Wait for initialization to complete
      await Future.delayed(Duration.zero);

      expect(authProvider.isLoading, false);
      expect(authProvider.isInitialized, true);
    });

    test('initAuth should handle valid token correctly', () async {
      when(mockAccountService.getToken()).thenAnswer((_) async => 'valid_token');
      when(mockAccountService.isValidToken()).thenAnswer((_) async => true);
      when(mockAccountService.setUserSession(token: 'valid_token')).thenAnswer((_) async {});

      authProvider = AuthProvider();
      await Future.delayed(Duration.zero); // Let initAuth complete

      expect(authProvider.isAuthenticated, true);
      expect(authProvider.token, 'valid_token');
      expect(authProvider.isLoading, false);
      expect(authProvider.isInitialized, true);
      verify(mockAccountService.setUserSession(token: 'valid_token')).called(1);
    });

    test('initAuth should handle invalid token correctly', () async {
      when(mockAccountService.getToken()).thenAnswer((_) async => 'invalid_token');
      when(mockAccountService.isValidToken()).thenAnswer((_) async => false);
      when(mockAccountService.logout()).thenAnswer((_) async {});

      authProvider = AuthProvider();
      await Future.delayed(Duration.zero); // Let initAuth complete

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, null);
      expect(authProvider.isLoading, false);
      expect(authProvider.isInitialized, true);
      verify(mockAccountService.logout()).called(1);
    });

    test('initAuth should handle no stored token correctly', () async {
      when(mockAccountService.getToken()).thenAnswer((_) async => null);

      authProvider = AuthProvider();
      await Future.delayed(Duration.zero); // Let initAuth complete

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, null);
      expect(authProvider.isLoading, false);
      expect(authProvider.isInitialized, true);
    });

    test('login should handle successful login correctly', () async {
      when(mockAccountService.getToken()).thenAnswer((_) async => null);
      authProvider = AuthProvider();
      await Future.delayed(Duration.zero); // Let initAuth complete

      when(mockAccountService.login('user', 'pass')).thenAnswer((_) async => {});
      when(mockAccountService.getToken()).thenAnswer((_) async => 'new_token');

      final result = await authProvider.login('user', 'pass');

      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.token, 'new_token');
      expect(authProvider.error, null);
      expect(authProvider.isLoading, false);
      verify(mockAccountService.login('user', 'pass')).called(1);
    });

    test('login should handle failed login correctly', () async {
      when(mockAccountService.getToken()).thenAnswer((_) async => null);
      authProvider = AuthProvider();
      await Future.delayed(Duration.zero); // Let initAuth complete

      when(mockAccountService.login('user', 'wrong_pass'))
          .thenThrow(Exception('Invalid credentials'));

      final result = await authProvider.login('user', 'wrong_pass');

      expect(result, false);
      expect(authProvider.error, contains('Invalid credentials'));
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, null);
      expect(authProvider.error, contains('Invalid credentials'));
      expect(authProvider.isLoading, false);
    });

    test('register should handle successful registration correctly', () async {
      when(mockAccountService.getToken()).thenAnswer((_) async => null);
      authProvider = AuthProvider();
      await Future.delayed(Duration.zero); // Let initAuth complete

      when(mockAccountService.register('user', 'email@test.com', 'pass'))
          .thenAnswer((_) async => {});
      when(mockAccountService.getToken()).thenAnswer((_) async => 'reg_token');

      final result = await authProvider.register('user', 'email@test.com', 'pass');

      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.token, 'reg_token');
      expect(authProvider.error, null);
      expect(authProvider.isLoading, false);
      verify(mockAccountService.register('user', 'email@test.com', 'pass')).called(1);
    });

    test('register should handle failed registration correctly', () async {
      when(mockAccountService.getToken()).thenAnswer((_) async => null);
      authProvider = AuthProvider();
      await Future.delayed(Duration.zero); // Let initAuth complete

      when(mockAccountService.register('user', 'invalid_email', 'pass'))
          .thenThrow(Exception('Invalid email'));

      final result = await authProvider.register('user', 'invalid_email', 'pass');

      expect(result, false);
      expect(authProvider.error, contains('Invalid email'));
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, null);
      expect(authProvider.error, contains('Invalid email'));
      expect(authProvider.isLoading, false);
    });

    test('logout should clear authentication state', () async {
      // Setup authenticated state
      when(mockAccountService.getToken()).thenAnswer((_) async => 'valid_token');
      when(mockAccountService.isValidToken()).thenAnswer((_) async => true);
      when(mockAccountService.setUserSession(token: 'valid_token')).thenAnswer((_) async {});

      authProvider = AuthProvider();
      await Future.delayed(Duration.zero); // Let initAuth complete

      when(mockAccountService.logout()).thenAnswer((_) async {});

      await authProvider.logout();

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.token, null);
      expect(authProvider.error, null);
      expect(authProvider.isLoading, false);
      verify(mockAccountService.logout()).called(1);
    });

    test('should notify listeners on state changes', () async {
      when(mockAccountService.getToken()).thenAnswer((_) async => null);
      authProvider = AuthProvider();
      await Future.delayed(Duration.zero); // Let initAuth complete

      bool notified = false;
      authProvider.addListener(() {
        notified = true;
      });

      when(mockAccountService.login('user', 'pass')).thenAnswer((_) async => {});
      when(mockAccountService.getToken()).thenAnswer((_) async => 'token');

      await authProvider.login('user', 'pass');
      expect(notified, true);
    });

    test('currentUserId should return UserSession id', () {
      when(mockAccountService.getToken()).thenAnswer((_) async => null);
      authProvider = AuthProvider();

      UserSession().id = 123;
      expect(authProvider.currentUserId, 123);
    });

    test('currentUserEmail should return UserSession email', () {
      when(mockAccountService.getToken()).thenAnswer((_) async => null);
      authProvider = AuthProvider();

      UserSession().email = 'test@example.com';
      expect(authProvider.currentUserEmail, 'test@example.com');
    });
  });
}