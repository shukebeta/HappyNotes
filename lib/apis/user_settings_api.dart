import 'package:dio/dio.dart';
import '../dio_client.dart';

class UserSettingsApi {
  static final Dio _dio = DioClient.getInstance();

  Future<Response> getAll() async {
    return await _dio.get('/settings/getAll');
  }

  Future<Response> upsert(String settingName, String settingValue) async {
    return await _dio.post('/settings/upsert', data: {
      'settingName': settingName,
      'settingValue': settingValue,
    });
  }
}
