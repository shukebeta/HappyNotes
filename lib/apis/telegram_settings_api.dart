import 'package:dio/dio.dart';
import 'package:happy_notes/entities/telegram_settings.dart';
import '../dio_client.dart';

class TelegramSettingsApi {
  static final Dio _dio = DioClient.getInstance();

  Future<Response> getAll() async {
    return await _dio.get('/telegramSettings/getAll');
  }

  Future<Response> add(TelegramSettings setting) async {
    var data = _getPostData(setting);
    return await _dio.post('/telegramSettings/add', data: data);
  }

  Future<Response> test(TelegramSettings setting) async {
    var data = _getPostData(setting);
    return await _dio.post('/telegramSettings/test', data: data);
  }

  Future<Response> activate(TelegramSettings setting) async {
    var data = _getPostData(setting);
    return await _dio.post('/telegramSettings/activate', data: data);
  }

  Map<String, Object?> _getPostData(TelegramSettings setting) {
    return {
      'syncType': setting.syncType,
      'syncValue': setting.syncValue,
      'encryptedToken': setting.encryptedToken,
      'tokenRemark': setting.tokenRemark,
      'channelId': setting.channelId,
      'channelName': setting.channelName ?? 'default name',
    };
  }

  Future<Response> disable(TelegramSettings setting) async {
    var data = _getPostData(setting);
    return await _dio.post('/telegramSettings/disable', data: data);
  }

  Future<Response> delete(TelegramSettings setting) async {
    var data = _getPostData(setting);
    return await _dio.delete('/telegramSettings/delete', data: data);
  }
}
