import 'package:dio/dio.dart';
import 'package:happy_notes/entities/telegram_settings.dart';
import '../dio_client.dart';

class TelegramSettingsApi {
  static final Dio _dio = DioClient.getInstance();

  Future<Response> getAll() async {
    return await _dio.get('/telegramSettings/getAll');
  }

  Future<Response> add(TelegramSettings setting) async {
    return await _dio.post('/telegramSettings/add', data: setting);
  }

  Future<Response> delete(TelegramSettings setting) async {
    return await _dio.delete('/telegramSettings/delete', data: setting);
  }
}
