import 'package:dio/dio.dart';

import '../app_config.dart';
import '../dio_client.dart';

class NotesApi {
  static final Dio _dio = DioClient.getInstance();

  static Future<Response> post(Map<String, dynamic> params) async {
    return await _dio.post('/note/post', data: params);
  }

  static Future<Response> update(Map<String, dynamic> params) async {
    if (params['id'] == null) {
      throw ArgumentError('The "id" parameter is required for the update operation.');
    }
    return await _dio.post('/note/update/${params['id']}', data: params);
  }

  static Future<Response> latest(Map<String, dynamic> params) async {
    final  options = Options(
      headers: {'AllowAnonymous': true},
    );
    var pager = params['pageSize'] > 0 && params['pageNumber'] > 0
      ? '/${params['pageSize']}/${params['pageNumber']}'
      : '/${AppConfig.defaultPageSize}/1';
    return await _dio.get('/notes/latest$pager', options: options);
  }

  static Future<Response> myLatest(Map<String, dynamic> params) async {
    var pager = params['pageSize'] > 0 && params['pageNumber'] > 0
        ? '/${params['pageSize']}/${params['pageNumber']}'
        : '/${AppConfig.defaultPageSize}/1';
    return await _dio.get('/notes/myLatest$pager');
  }

}
