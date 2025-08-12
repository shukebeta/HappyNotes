import 'package:flutter_test/flutter_test.dart';
import 'package:happy_notes/providers/provider_base.dart';
import 'package:happy_notes/exceptions/custom_exception.dart';

// Mock implementation for testing
class MockAuthAwareProvider extends AuthAwareProvider {
  bool _isLoading = false;
  String? _error;
  List<String> _data = [];
  List<String> callLog = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get data => _data;

  @override
  Future<void> onLogin() async {
    callLog.add('onLogin');
    _data = ['login_data'];
    notifyListeners();
  }

  @override
  Future<void> onLogout() async {
    callLog.add('onLogout');
    await super.onLogout(); // This calls clearAllData()
  }

  @override
  void clearAllData() {
    callLog.add('clearAllData');
    _data = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // Helper method for testing resetAuthState
  void testResetAuthState() {
    resetAuthState();
  }

  // Helper method for testing handleServiceError
  String testHandleServiceError(dynamic error, String operation) {
    return handleServiceError(error, operation);
  }

  // Helper methods for testing executeWithErrorHandling
  Future<String> testSuccessfulOperation() async {
    final result = await executeWithErrorHandling<String>(
      operation: () async => 'success',
      setLoading: (loading) => _isLoading = loading,
      setError: (error) => _error = error,
      operationName: 'test operation',
    );
    return result ?? '';
  }

  Future<String> testFailedOperation() async {
    final result = await executeWithErrorHandling<String>(
      operation: () async => throw CustomException('Test error'),
      setLoading: (loading) => _isLoading = loading,
      setError: (error) => _error = error,
      operationName: 'test operation',
    );
    return result ?? '';
  }
}

void main() {
  group('AuthAwareProvider', () {
    late MockAuthAwareProvider provider;

    setUp(() {
      provider = MockAuthAwareProvider();
    });

    test('initial state should be correct', () {
      expect(provider.isAuthStateInitialized, false);
      expect(provider.data, isEmpty);
      expect(provider.callLog, isEmpty);
    });

    test('onAuthStateChanged should handle login correctly', () async {
      await provider.onAuthStateChanged(true);

      expect(provider.isAuthStateInitialized, true);
      expect(provider.callLog, contains('onLogin'));
      expect(provider.data, ['login_data']);
    });

    test('onAuthStateChanged should handle logout correctly', () async {
      // First login
      await provider.onAuthStateChanged(true);
      provider.callLog.clear();

      // Simulate AppStateProvider's logout flow: clear data first, then notify auth change
      provider.clearAllData();
      await provider.onAuthStateChanged(false);

      expect(provider.isAuthStateInitialized, false);
      expect(provider.callLog, contains('clearAllData'));
      expect(provider.callLog, contains('onLogout'));
      // Data should always be empty after clearAllData() call
      expect(provider.data, isEmpty);
    });

    test('onAuthStateChanged should not call onLogout if not initialized', () async {
      await provider.onAuthStateChanged(false);

      expect(provider.isAuthStateInitialized, false);
      expect(provider.callLog, isEmpty);
    });

    test('resetAuthState should reset initialization flag', () async {
      await provider.onAuthStateChanged(true);
      expect(provider.isAuthStateInitialized, true);

      // Test resetAuthState through a subclass method
      provider.testResetAuthState();
      expect(provider.isAuthStateInitialized, false);
    });

    group('handleServiceError', () {
      test('should handle CustomException correctly', () {
        final error = CustomException('Custom error message');
        final result = provider.testHandleServiceError(error, 'test operation');
        expect(result, 'Custom error message');
      });

      test('should handle generic Exception correctly', () {
        final error = Exception('Generic error');
        final result = provider.testHandleServiceError(error, 'test operation');
        expect(result, 'Failed to test operation: Exception: Generic error');
      });

      test('should handle non-Exception errors correctly', () {
        const error = 'String error';
        final result = provider.testHandleServiceError(error, 'test operation');
        expect(result, 'Failed to test operation: String error');
      });
    });

    group('executeWithErrorHandling', () {
      test('should handle successful operation correctly', () async {
        final result = await provider.testSuccessfulOperation();

        expect(result, 'success');
        expect(provider.isLoading, false);
        expect(provider.error, null);
      });

      test('should handle failed operation correctly', () async {
        final result = await provider.testFailedOperation();

        expect(result, '');
        expect(provider.isLoading, false);
        expect(provider.error, 'Test error');
      });
    });

    test('should notify listeners on auth state changes', () async {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.onAuthStateChanged(true);
      expect(notified, true);
    });
  });
}