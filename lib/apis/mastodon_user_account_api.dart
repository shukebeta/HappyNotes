import 'package:dio/dio.dart';
import 'package:happy_notes/entities/mastodon_user_account.dart';
import '../dio_client.dart';

class MastodonUserAccountApi {
  static final Dio _dio = DioClient.getInstance();

  Future<Response> setState(String state) async {
    final  options = Options(
      headers: {'X-State': state},
    );
    // we don't have a separate api file for mastodon auth
    return await _dio.post('/mastodonAuth/setState', options: options);
  }

  Future<Response> getAll() async {
    return await _dio.get('/mastodonUserAccount/getAll');
  }

  Future<Response> add(MastodonUserAccount account) async {
    var data = _getPostData(account);
    return await _dio.post('/mastodonUserAccount/add', data: data);
  }

  Future<Response> test(MastodonUserAccount account) async {
    var data = _getPostData(account);
    return await _dio.post('/mastodonUserAccount/test', data: data);
  }

  Future<Response> activate(MastodonUserAccount account) async {
    var data = _getPostData(account);
    return await _dio.post('/mastodonUserAccount/activate', data: data);
  }

  Map<String, Object?> _getPostData(MastodonUserAccount account) {
    return {
      'userId': account.userId,
      'instanceUrl': account.instanceUrl,
      'scope': account.scope,
      'accessToken': account.accessToken,
      'refreshToken': account.refreshToken,
      'tokenType': account.tokenType,
    };
  }

  Future<Response> disable(MastodonUserAccount account) async {
    var data = _getPostData(account);
    return await _dio.post('/mastodonUserAccount/disable', data: data);
  }

  Future<Response> delete(MastodonUserAccount account) async {
    var data = _getPostData(account);
    return await _dio.delete('/mastodonUserAccount/delete', data: data);
  }
}
