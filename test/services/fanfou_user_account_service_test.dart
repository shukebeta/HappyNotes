import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_notes/apis/fanfou_user_account_api.dart';
import 'package:happy_notes/exceptions/api_exception.dart';
import 'package:happy_notes/services/fanfou_user_account_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'fanfou_user_account_service_test.mocks.dart';

@GenerateMocks([FanfouUserAccountApi])
Response<dynamic> _resp(Map<String, dynamic> data) => Response(requestOptions: RequestOptions(path: '/'), data: data);

void main() {
  late MockFanfouUserAccountApi api;
  late FanfouUserAccountService service;

  setUp(() {
    api = MockFanfouUserAccountApi();
    service = FanfouUserAccountService(fanfouUserAccountApi: api);
  });

  group('getAll', () {
    test('maps the response data list to entities', () async {
      when(api.getAll()).thenAnswer((_) async => _resp({
            'successful': true,
            'data': [
              {
                'id': 1,
                'userId': 7,
                'syncType': 2,
                'status': 1,
                'fanfouUserId': 'happy_user',
                'statusText': 'Normal',
              },
            ],
          }));

      final result = await service.getAll();

      expect(result, hasLength(1));
      expect(result.first.id, 1);
      expect(result.first.fanfouUserId, 'happy_user');
      expect(result.first.syncType, 2);
    });
  });

  group('requestToken', () {
    test('returns the authorize URL on success', () async {
      when(api.requestToken()).thenAnswer((_) async => _resp({
            'successful': true,
            'data': 'https://fanfou.com/oauth/authorize?oauth_token=abc',
          }));

      expect(await service.requestToken(), 'https://fanfou.com/oauth/authorize?oauth_token=abc');
    });

    test('throws ApiException when the call is not successful', () async {
      when(api.requestToken()).thenAnswer((_) async => _resp({
            'successful': false,
            'errorCode': 1,
            'errorMessage': 'boom',
          }));

      expect(service.requestToken(), throwsA(isA<ApiException>()));
    });
  });

  group('bodyless mutations', () {
    test('nextSyncType completes on success and calls the endpoint', () async {
      when(api.nextSyncType()).thenAnswer((_) async => _resp({'successful': true}));

      await service.nextSyncType();

      verify(api.nextSyncType()).called(1);
    });

    test('activate returns true on success', () async {
      when(api.activate()).thenAnswer((_) async => _resp({'successful': true}));
      expect(await service.activate(), isTrue);
    });

    test('disable returns true on success', () async {
      when(api.disable()).thenAnswer((_) async => _resp({'successful': true}));
      expect(await service.disable(), isTrue);
    });

    test('delete returns true on success', () async {
      when(api.delete()).thenAnswer((_) async => _resp({'successful': true}));
      expect(await service.delete(), isTrue);
    });

    test('a failed mutation throws ApiException', () async {
      when(api.disable()).thenAnswer((_) async => _resp({
            'successful': false,
            'errorCode': 1,
            'errorMessage': 'no account',
          }));

      expect(service.disable(), throwsA(isA<ApiException>()));
    });
  });
}
