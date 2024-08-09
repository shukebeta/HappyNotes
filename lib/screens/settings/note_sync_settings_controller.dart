import 'package:flutter/material.dart';
import 'package:happy_notes/entities/telegram_settings.dart';

import '../../services/telegram_settings_service.dart';
import '../../utils/util.dart';

class NoteSyncSettingsController {
  final TelegramSettingsService _telegramSettingService;
  bool isLoading = false;
  List<TelegramSettings> telegramSettings = [];

  NoteSyncSettingsController({required TelegramSettingsService telegramSettingService})
      :_telegramSettingService = telegramSettingService;

  Future<void> getTelegramSettings(BuildContext context) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      isLoading = true;
      telegramSettings = await _telegramSettingService.getAll();
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    } finally {
      isLoading = false;
    }
  }

  Future<bool> addTelegramSetting(TelegramSettings setting) async {
    return await _telegramSettingService.add(setting);
  }

  Future<bool> testTelegramSetting(TelegramSettings setting) async {
    return await _telegramSettingService.test(setting);
  }

  Future<bool> activateTelegramSetting(TelegramSettings setting) async {
    return await _telegramSettingService.activate(setting);
  }

  Future<bool> disableTelegramSetting(TelegramSettings setting) async {
    return await _telegramSettingService.disable(setting);
  }

  Future<bool> deleteTelegramSetting(TelegramSettings setting) async {
    return await _telegramSettingService.delete(setting);
  }


}
