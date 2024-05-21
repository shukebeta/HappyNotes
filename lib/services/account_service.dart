import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:happy_notes/apis/account_api.dart';
import 'package:happy_notes/app_config.dart';
import 'package:happy_notes/utils/token_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../dependency_injection.dart';

class AccountService {
  final _tokenKey = 'accessToken';
  final _baseUrlKey = 'baseUrl';
  final _storage = locator<FlutterSecureStorage>();
  final _tokenUtils = locator<TokenUtils>();
  Future<dynamic> login(String username, String password) async {
    var params = {'username': username, 'password': password};
    final apiResponse = (await AccountApi.login(params)).data;
    if (apiResponse['successful']) {
      await _storeToken(apiResponse['data']['token']);
    } else {
      throw Exception(apiResponse['message']);
    }
    return apiResponse;
  }

  Future<dynamic> register(String username, String email, String password) async {
    var params = {'username': username, 'email': email, 'password': password};
    var apiResponse = (await AccountApi.register(params)).data;
    if (apiResponse['successful']) {
      await _storeToken(apiResponse['data']['token']);
    } else {
      throw Exception(apiResponse['message']);
    }
    return apiResponse;
  }

  Future<dynamic> _refreshToken() async {
    var apiResponse = (await AccountApi.refreshToken()).data;
    if (apiResponse['successful']) {
      _storeToken(apiResponse['data']['token']);
    }
  }

  Future<void> _storeToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _baseUrlKey, value: AppConfig.baseUrl);
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: _tokenKey);
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
    final previousBaseUrl = await _storage.read(key: _baseUrlKey);
    return previousBaseUrl == AppConfig.baseUrl;
  }
}
