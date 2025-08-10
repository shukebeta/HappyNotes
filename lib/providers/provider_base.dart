import 'package:flutter/foundation.dart';
import 'package:happy_notes/exceptions/custom_exception.dart';

/// Base class for providers that need to respond to authentication state changes
abstract class AuthAwareProvider with ChangeNotifier {
  bool _isAuthStateInitialized = false;
  bool get isAuthStateInitialized => _isAuthStateInitialized;

  /// Called when the user logs in successfully
  /// Override this to load initial data after login
  @protected
  Future<void> onLogin() async {
    // Default implementation does nothing
    // Subclasses can override to load data
  }

  /// Called when the user logs out
  /// Override this to perform custom cleanup. Do not clear data here by default.
  @protected
  Future<void> onLogout() async {
    // Default implementation is a no-op; AppStateProvider handles clearing.
  }

  /// Called when auth state changes
  /// This is called by AppStateProvider
  Future<void> onAuthStateChanged(bool isAuthenticated) async {
    if (isAuthenticated) {
      // Always initialize on login, regardless of previous state
      // This ensures clean state for each user session
      _isAuthStateInitialized = true;

      // Note: clearAllData() is already called by AppStateProvider
      // We don't call it again here to avoid double clearing

      // Add a small delay to ensure UI updates with cleared state
      // before loading new data
      await Future.delayed(const Duration(milliseconds: 100));

      await onLogin();
    } else {
      if (_isAuthStateInitialized) {
        _isAuthStateInitialized = false;
        await onLogout();
      }
    }
  }

  /// Clear all cached data
  /// All auth-aware providers must implement this method
  void clearAllData();

  /// Reset the auth state initialization flag
  /// Used for testing purposes
  @protected
  void resetAuthState() {
    _isAuthStateInitialized = false;
  }

  /// Standardized error handling for service operations
  /// Returns a user-friendly error message from any exception
  @protected
  String handleServiceError(dynamic error, String operation) {
    if (error is CustomException) {
      return error.message;
    } else if (error is Exception) {
      return 'Failed to $operation: ${error.toString()}';
    } else {
      return 'Failed to $operation: $error';
    }
  }

  /// Execute an async operation with standardized error handling
  /// Sets loading state, executes operation, handles errors, and notifies listeners
  @protected
  Future<T?> executeWithErrorHandling<T>({
    required Future<T> Function() operation,
    required void Function(bool) setLoading,
    required void Function(String?) setError,
    required String operationName,
    void Function()? onSuccess,
  }) async {
    setLoading(true);
    setError(null);
    notifyListeners();

    try {
      final result = await operation();
      onSuccess?.call();
      return result;
    } catch (e) {
      setError(handleServiceError(e, operationName));
      return null;
    } finally {
      setLoading(false);
      notifyListeners();
    }
  }
}