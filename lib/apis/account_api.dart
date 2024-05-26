import 'package:dio/dio.dart';
import '../dio_client.dart';

class AccountApi {
  static final Dio _dio = DioClient.getInstance();

  Future<Response> login(Map<String, dynamic> params) async {
    final  options = Options(
      headers: {'AllowAnonymous': true},
    );
    return await _dio.post('/account/login', data: params, options: options);
  }

  Future<Response> register(Map<String, dynamic> params) async {
    final options = Options(
      headers: {'AllowAnonymous': true},
    );
    return await _dio.post('/account/register', data: params);
  }

  Future<Response> refreshToken() async {
    return await _dio.post('/account/refreshToken', data: {});
  }
}
