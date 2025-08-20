import 'package:happy_notes/exceptions/api_exception.dart';
import '../apis/telegram_settings_api.dart';
import '../entities/telegram_settings.dart';

class TelegramSettingsService {
  final TelegramSettingsApi _telegramSettingsApi;
  TelegramSettingsService({required TelegramSettingsApi telegramSettingsApi})
      : _telegramSettingsApi = telegramSettingsApi;

  Future<List<TelegramSettings>> getAll() async {
    List<dynamic> apiResult = (await _telegramSettingsApi.getAll()).data['data'];
    return apiResult.map((json) => TelegramSettings.fromJson(json)).toList();
  }

  Future<bool> add(TelegramSettings setting) async {
    final apiResult = (await _telegramSettingsApi.add(setting)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<bool> test(TelegramSettings setting) async {
    final apiResult = (await _telegramSettingsApi.test(setting)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<bool> delete(TelegramSettings setting) async {
    final apiResult = (await _telegramSettingsApi.delete(setting)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<bool> disable(TelegramSettings setting) async {
    final apiResult = (await _telegramSettingsApi.disable(setting)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<bool> activate(TelegramSettings setting) async {
    final apiResult = (await _telegramSettingsApi.activate(setting)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }
}
