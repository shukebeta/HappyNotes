import 'package:happy_notes/apis/user_settings_api.dart';
import 'package:happy_notes/entities/user_settings.dart';
import 'package:happy_notes/exceptions/api_exception.dart';
import 'package:happy_notes/screens/account/user_session.dart';

class UserSettingsService {
  final UserSettingsApi _userSettingsApi;
  UserSettingsService({required UserSettingsApi userSettingsApi}) : _userSettingsApi = userSettingsApi;

  Future<List<UserSettings>> getAll() async {
    List<dynamic> apiResult = (await _userSettingsApi.getAll()).data['data'];
    final settings = apiResult.map(_deserializeUserSettings).toList();
    _replaceSessionSettings(settings);
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
    _replaceSessionSettings(currentSettings);
    return true;
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
