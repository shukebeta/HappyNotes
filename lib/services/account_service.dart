import 'package:happy_notes/apis/account_api.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/utils/token_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dependency_injection.dart';
import '../exceptions/custom_exception.dart';

class AccountService {
  final AccountApi _accountApi;
  AccountService({required AccountApi accountApi}): _accountApi = accountApi;
  final _tokenKey = 'accessToken';
  final _baseUrlKey = 'baseUrl';
  final _tokenUtils = locator<TokenUtils>();
  Future<dynamic> login(String username, String password) async {
    var params = {'username': username, 'password': password};
    final apiResponse = (await _accountApi.login(params)).data;
    if (apiResponse['successful']) {
      await _storeToken(apiResponse['data']['token']);
    } else {
      throw CustomException(apiResponse['message']);
    }
    return apiResponse;
  }

  Future<void> logout() async {
    await _clearToken();
  }

  Future<dynamic> register(String username, String email, String password) async {
    var params = {'username': username, 'email': email, 'password': password};
    var apiResponse = (await _accountApi.register(params)).data;
    if (apiResponse['successful']) {
      await _storeToken(apiResponse['data']['token']);
    } else {
      throw Exception(apiResponse['message']);
    }
    return apiResponse;
  }

  Future<dynamic> _refreshToken() async {
    var apiResponse = (await _accountApi.refreshToken()).data;
    if (apiResponse['successful']) {
      _storeToken(apiResponse['data']['token']);
    }
  }

  Future<void> _storeToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_baseUrlKey, AppConfig.baseUrl);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, '');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      var remainingTime = await _tokenUtils.getTokenRemainingTime(token);
      if (remainingTime.inDays <= 30) {
        try {
          //we deliberately don't use await here to avoid blocking the getToken operation
          _refreshToken();
        } catch (e) {
          // eat the exception
        }
      }
    }
    return token;
  }

  Future<bool> isValidToken() async {
    if (await _isSameEnv()) {
      final token = await getToken();
      if (token != null) {
        return (await _tokenUtils.getTokenRemainingTime(token)).inSeconds >= 1;
      }
    }
    return false;
  }

  // if env changes, even the token is valid, we still need to ask user to log in
  Future<bool> _isSameEnv() async {
    final prefs = await SharedPreferences.getInstance();
    final previousBaseUrl = prefs.getString(_baseUrlKey);
    return previousBaseUrl == AppConfig.baseUrl;
  }
}
