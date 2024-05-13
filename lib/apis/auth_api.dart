import 'package:dio/dio.dart';

import '../dio_client.dart';

class AuthApi {
  static final Dio _dio = DioClient.getInstance();

  static Future<Response> login(Map<String, dynamic> params) async {
      return await _dio.post('/account/login', data: params);
  }

  static Future<Response> register(Map<String, dynamic> params) async {
      return await _dio.get('/channel/list', data: params);
  }

}
