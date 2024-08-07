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

  // Future<bool> addTelegramSetting(Map<String, dynamic> setting) async {
  //   // Implement your API call to add a Telegram Sync Setting here
  //   // Return true if the setting was added successfully
  // }
  //
  // Future<bool> activateTelegramSetting(int id) async {
  //   // Implement your API call to delete a Telegram Sync Setting by ID here
  //   // Return true if the setting was deleted successfully
  // }
  //
  // Future<bool> disableTelegramSetting(int id) async {
  //   // Implement your API call to delete a Telegram Sync Setting by ID here
  //   // Return true if the setting was deleted successfully
  // }
  //
  // Future<bool> deleteTelegramSetting(int id) async {
  //   // Implement your API call to delete a Telegram Sync Setting by ID here
  //   // Return true if the setting was deleted successfully
  // }


}
