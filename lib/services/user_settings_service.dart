import 'package:happy_notes/apis/user_settings_api.dart';
import 'package:happy_notes/entities/user_settings.dart';

class UserSettingsService {
  final UserSettingsApi _userSettingsApi;
  UserSettingsService({required UserSettingsApi userSettingsApi}): _userSettingsApi = userSettingsApi;
 
  Future<List<UserSettings>> getAll() async {
    List<dynamic> apiResult = (await _userSettingsApi.getAll()).data['data'];
    return apiResult.map((json) => UserSettings.fromJson(json)).toList();
  }
  
  
}