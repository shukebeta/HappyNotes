import 'package:dio/dio.dart';

import '../dio_client.dart';

class NoteTagApi {
  static final Dio _dio = DioClient.getInstance();

  Future<Response> getMyTagCloud() async {
    return await _dio.get('/tag/myTagCloud');
  }
}