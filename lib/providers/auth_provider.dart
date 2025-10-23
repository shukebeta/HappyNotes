import 'package:flutter/material.dart';
import 'package:happy_notes/services/account_service.dart';
import 'package:happy_notes/screens/account/user_session.dart';
import 'package:happy_notes/dependency_injection.dart';
import 'package:happy_notes/services/seq_logger.dart';

class AuthProvider with ChangeNotifier {
  final AccountService _accountService = locator<AccountService>();

  String? _token;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    initAuth();
  }

  Future<void> initAuth() async {
    if (_isInitialized) return; // Prevent multiple initializations

    _isLoading = true;
    notifyListeners();

    try {
      final storedToken = await _accountService.getToken();

      if (storedToken != null && storedToken.isNotEmpty) {
        // Validate token with timeout and fallback
        bool isValid = false;
        
        try {
          // Add timeout to token validation to prevent hanging
          isValid = await _accountService.isValidToken()
              .timeout(const Duration(seconds: 10));
        } catch (e) {
          // If validation times out or fails, try local validation first
          SeqLogger.info('Token validation timeout/error, falling back to local validation: $e');
          try {
            isValid = await _accountService.isValidTokenLocally();
          } catch (localError) {
            SeqLogger.severe('Local token validation failed: $localError');
            isValid = false;
          }
        }

        if (isValid) {
          _token = storedToken;
          // Ensure session is populated - do this in background if it times out
          try {
            await _accountService.setUserSession(token: _token)
                .timeout(const Duration(seconds: 8));
          } catch (sessionError) {
            SeqLogger.info('Session setup timeout, continuing with stored token: $sessionError');
            // Continue anyway - user can still use the app
          }
        } else {
          _token = null; // Token is invalid or expired
          await _accountService.logout(); // Clear any stale session data
        }
      }
    } catch (e) {
      SeqLogger.severe('Failed to initialize authentication: $e');
      _error = 'Failed to initialize authentication: ${e.toString()}';
      _token = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _accountService.login(username, password);
      // After successful login, get the stored token
      _token = await _accountService.getToken();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _token = null;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _accountService.register(username, email, password);
      // After successful registration, get the stored token
      _token = await _accountService.getToken();
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _token = null;
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _accountService.logout();

    _token = null;
    _error = null;
    _isLoading = false;
    notifyListeners();

    // Data clearing will be handled automatically by AppStateProvider
    // listening to auth state changes
  }

  /// Get current user ID from session
  int? get currentUserId => UserSession().id;

  /// Get current user email from session
  String? get currentUserEmail => UserSession().email;

  /// Retry authentication initialization
  /// Useful when network conditions improve or user manually retries
  Future<void> retryAuth() async {
    _isInitialized = false;
    _error = null;
    await initAuth();
  }
}
