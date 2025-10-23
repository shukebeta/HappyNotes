import 'package:happy_notes/apis/account_api.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/services/user_settings_service.dart';
import 'package:happy_notes/utils/app_logger_interface.dart';
import 'package:happy_notes/utils/token_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../exceptions/api_exception.dart';
import '../screens/account/user_session.dart';

class AccountService {
  final AccountApi _accountApi;
  final UserSettingsService _userSettingsService;
  final TokenUtils _tokenUtils;
  final AppLoggerInterface _logger;

  AccountService({
    required AccountApi accountApi,
    required UserSettingsService userSettingsService,
    required TokenUtils tokenUtils,
    required AppLoggerInterface logger,
  })  : _accountApi = accountApi,
        _userSettingsService = userSettingsService,
        _tokenUtils = tokenUtils,
        _logger = logger;

  Future<dynamic> login(String username, String password) async {
    var params = {'username': username, 'password': password};
    final apiResult = (await _accountApi.login(params)).data;
    if (apiResult['successful']) {
      await _storeToken(apiResult['data']['token']);
    } else {
      throw ApiException(apiResult);
    }
    return apiResult;
  }

  Future<void> logout() async {
    await _clearToken();
  }

  Future<dynamic> register(String username, String email, String password) async {
    var params = {'username': username, 'email': email, 'password': password};
    var apiResult = (await _accountApi.register(params)).data;
    if (apiResult['successful']) {
      await _storeToken(apiResult['data']['token']);
    } else {
      throw ApiException(apiResult);
    }
    return apiResult;
  }

  Future<dynamic> _refreshToken() async {
    try {
      var apiResponse = (await _accountApi.refreshToken()).data;
      if (apiResponse['successful']) {
        await _storeToken(apiResponse['data']['token']);
        _logger.i('Token refreshed successfully');
      } else {
        _logger.e('Token refresh failed: ${apiResponse['message'] ?? 'Unknown error'}');
        throw ApiException(apiResponse);
      }
    } catch (e) {
      _logger.e('Token refresh error: ${e.toString()}');
      rethrow;
    }
  }

  final _tokenKey = 'accessToken';
  final _baseUrlKey = 'baseUrl';
  final String _payloadUserIdKey = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';
  final String _payloadEmailKey = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress';

  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await setUserSession(token: token);
    await prefs.setString(_baseUrlKey, AppConfig.apiBaseUrl);
    await prefs.setString(_tokenKey, token);
  }

  Future<void> setUserSession({String? token}) async {
    token ??= await getToken();
    var payload = await _tokenUtils.decodeToken(token!);
    UserSession().id = int.parse(payload[_payloadUserIdKey]);
    UserSession().email = payload[_payloadEmailKey];
    UserSession().userSettings = await _userSettingsService.getAll();
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_baseUrlKey);
    UserSession().id = null;
    UserSession().email = null;
    UserSession().userSettings = null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null && token != '') {
      try {
        var remainingTime = await _tokenUtils.getTokenRemainingTime(token);
        if (remainingTime.inDays <= 30) {
          try {
            // Add timeout to refresh token operation
            await _refreshToken().timeout(const Duration(seconds: 15));
          } catch (e) {
            _logger.e('Token refresh failed or timed out: ${e.toString()}');
            // Continue with existing token if refresh fails
          }
        }
      } catch (e) {
        _logger.e('Error checking token expiration: ${e.toString()}');
        // Continue with existing token if expiration check fails
      }
    }
    return token;
  }

  Future<bool> isValidToken() async {
    if (await _isSameEnv()) {
      final token = await getToken();
      if (token != null && token != '') {
        try {
          return (await _tokenUtils.getTokenRemainingTime(token)).inSeconds >= 1;
        } catch (e) {
          _logger.e(e.toString());
          return false;
        }
      }
    }
    return false;
  }

  /// Local token validation that doesn't require network calls
  /// Used as fallback when network validation times out
  Future<bool> isValidTokenLocally() async {
    if (await _isSameEnv()) {
      final token = await getToken();
      if (token != null && token != '') {
        try {
          // Only check token structure and expiration locally
          final remainingTime = await _tokenUtils.getTokenRemainingTime(token);
          // Give more buffer time for local validation (5 minutes instead of 1 second)
          return remainingTime.inMinutes >= 5;
        } catch (e) {
          _logger.e('Local token validation error: ${e.toString()}');
          return false;
        }
      }
    }
    return false;
  }

  // if env changes, even the token is valid, we still need to ask user to log in
  Future<bool> _isSameEnv() async {
    final prefs = await SharedPreferences.getInstance();
    final previousBaseUrl = prefs.getString(_baseUrlKey);
    return previousBaseUrl == AppConfig.apiBaseUrl;
  }
}
