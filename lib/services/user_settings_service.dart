import 'dart:convert';

import 'package:happy_notes/apis/user_settings_api.dart';
import 'package:happy_notes/app_constants.dart';
import 'package:happy_notes/entities/user_settings.dart';
import 'package:happy_notes/exceptions/api_exception.dart';
import 'package:happy_notes/services/seq_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_notes/screens/account/user_session.dart';

class UserSettingsService {
  final UserSettingsApi _userSettingsApi;
  UserSettingsService({required UserSettingsApi userSettingsApi}) : _userSettingsApi = userSettingsApi;

  Future<List<UserSettings>> getAll() async {
    List<dynamic> apiResult = (await _userSettingsApi.getAll()).data['data'];
    final settings = apiResult.map(_deserializeUserSettings).toList();
    await _replaceSessionAndCache(settings);
    return settings;
  }

  Future<bool> upsert(String settingName, String settingValue) async {
    final apiResult = (await _userSettingsApi.upsert(settingName, settingValue)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    final currentSettings = List<UserSettings>.from(UserSession().userSettings ?? const <UserSettings>[]);
    final index = currentSettings.indexWhere((el) => el.settingName == settingName);
    if (index >= 0) {
      currentSettings[index].settingValue = settingValue;
    } else {
      currentSettings.add(
        UserSettings(
          id: 0,
          userId: UserSession().id ?? 0,
          settingName: settingName,
          settingValue: settingValue,
        ),
      );
    }
    await _replaceSessionAndCache(currentSettings);
    return true;
  }

  Future<bool> hydrateSessionFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedSettings = prefs.getString(AppConstants.cachedUserSettings);
    if (cachedSettings == null || cachedSettings.isEmpty) {
      return false;
    }

    try {
      final decoded = jsonDecode(cachedSettings);
      if (decoded is! List) {
        await prefs.remove(AppConstants.cachedUserSettings);
        return false;
      }

      final settings = decoded.map(_deserializeUserSettings).toList();
      _replaceSessionSettings(settings);
      return settings.isNotEmpty;
    } catch (e) {
      SeqLogger.severe('UserSettingsService.hydrateSessionFromCache: Failed to restore cached settings: $e');
      await prefs.remove(AppConstants.cachedUserSettings);
      return false;
    }
  }

  Future<void> clearCachedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.cachedUserSettings);
  }

  Future<void> _replaceSessionAndCache(List<UserSettings> settings) async {
    _replaceSessionSettings(settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.cachedUserSettings,
      jsonEncode(UserSession().userSettings!.map((setting) => setting.toJson()).toList()),
    );
  }

  UserSettings _deserializeUserSettings(dynamic json) {
    return UserSettings.fromJson(Map<String, dynamic>.from(json));
  }

  void _replaceSessionSettings(List<UserSettings> settings) {
    final existingSettings = UserSession().userSettings;
    if (existingSettings == null) {
      UserSession().userSettings = List<UserSettings>.from(settings);
      return;
    }

    existingSettings
      ..clear()
      ..addAll(settings);
  }
}
