import 'dart:convert';

import 'package:happy_notes/apis/user_settings_api.dart';
import 'package:happy_notes/entities/user_settings.dart';
import 'package:happy_notes/exceptions/api_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:happy_notes/screens/account/user_session.dart';

class UserSettingsService {
  static const String _cachedUserSettingsKey = 'cachedUserSettings';
  final UserSettingsApi _userSettingsApi;
  UserSettingsService({required UserSettingsApi userSettingsApi}) : _userSettingsApi = userSettingsApi;

  Future<List<UserSettings>> getAll() async {
    List<dynamic> apiResult = (await _userSettingsApi.getAll()).data['data'];
    final settings = apiResult.map((json) => UserSettings.fromJson(Map<String, dynamic>.from(json))).toList();
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
    final cachedSettings = prefs.getString(_cachedUserSettingsKey);
    if (cachedSettings == null || cachedSettings.isEmpty) {
      return false;
    }

    final decoded = jsonDecode(cachedSettings);
    if (decoded is! List) {
      await prefs.remove(_cachedUserSettingsKey);
      return false;
    }

    final settings = decoded
        .map((item) => UserSettings.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    UserSession().userSettings = settings;
    return settings.isNotEmpty;
  }

  Future<void> clearCachedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUserSettingsKey);
  }

  Future<void> _replaceSessionAndCache(List<UserSettings> settings) async {
    UserSession().userSettings = List<UserSettings>.from(settings);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cachedUserSettingsKey,
      jsonEncode(UserSession().userSettings!.map((setting) => setting.toJson()).toList()),
    );
  }
}
