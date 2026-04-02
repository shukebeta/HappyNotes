import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_notes/apis/account_api.dart';
import 'package:happy_notes/apis/user_settings_api.dart';
import 'package:happy_notes/entities/user_settings.dart';
import 'package:happy_notes/services/account_service.dart';
import 'package:happy_notes/services/user_settings_service.dart';
import 'package:happy_notes/utils/token_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers/seq_logger_setup.dart';

class FakeAccountApi extends AccountApi {
  int refreshCalls = 0;

  @override
  Future<Response> refreshToken() async {
    refreshCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return Response<dynamic>(
      requestOptions: RequestOptions(path: '/account/refreshToken'),
      data: {
        'successful': true,
        'data': {'token': 'refreshed-token'},
      },
    );
  }
}

class FakeUserSettingsService extends UserSettingsService {
  FakeUserSettingsService() : super(userSettingsApi: FakeUserSettingsApi());

  @override
  Future<List<UserSettings>> getAll() async {
    return <UserSettings>[];
  }

  @override
  Future<void> clearCachedSettings() async {}
}

class FakeUserSettingsApi extends UserSettingsApi {}

class FakeTokenUtils extends TokenUtils {
  @override
  Future<Map<String, dynamic>> decodeToken(String token) async {
    return {
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier': '123',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress': 'test@example.com',
      'exp': DateTime.now().add(const Duration(days: 10)).millisecondsSinceEpoch ~/ 1000,
    };
  }

  @override
  Future<Duration> getTokenRemainingTime(String token) async {
    return const Duration(days: 10);
  }
}

void main() {
  group('AccountService', () {
    late FakeAccountApi fakeAccountApi;
    late AccountService accountService;

    setUp(() {
      setupSeqLoggerForTesting();
      SharedPreferences.setMockInitialValues({'accessToken': 'stored-token'});
      fakeAccountApi = FakeAccountApi();
      accountService = AccountService(
        accountApi: fakeAccountApi,
        userSettingsService: FakeUserSettingsService(),
        tokenUtils: FakeTokenUtils(),
      );
    });

    test('getToken only triggers one refresh while a refresh is already in flight', () async {
      await Future.wait([
        accountService.getToken(),
        accountService.getToken(),
        accountService.getToken(),
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 120));

      expect(fakeAccountApi.refreshCalls, 1);
    });
  });
}
