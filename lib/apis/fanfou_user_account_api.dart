import 'package:dio/dio.dart';
import '../dio_client.dart';

class FanfouUserAccountApi {
  static final Dio _dio = DioClient.getInstance();

  /// First OAuth leg: ask the backend for a request token and the Fanfou
  /// authorize URL the user should be sent to. Returns the raw ApiResult.
  Future<Response> requestToken() async {
    return await _dio.post('/fanfouAuth/requestToken');
  }

  Future<Response> getAll() async {
    return await _dio.get('/fanfouUserAccount/getAll');
  }

  // The mutating endpoints act on the current user's single Fanfou account and
  // take no request body.
  Future<Response> nextSyncType() async {
    return await _dio.post('/fanfouUserAccount/nextSyncType');
  }

  Future<Response> activate() async {
    return await _dio.post('/fanfouUserAccount/activate');
  }

  Future<Response> disable() async {
    return await _dio.post('/fanfouUserAccount/disable');
  }

  Future<Response> delete() async {
    return await _dio.delete('/fanfouUserAccount/delete');
  }
}
