import 'package:happy_notes/exceptions/api_exception.dart';
import '../apis/mastodon_user_account_api.dart';
import '../entities/mastodon_user_account.dart';

class MastodonUserAccountService {
  final MastodonUserAccountApi _mastodonSettingsApi;
  MastodonUserAccountService({required MastodonUserAccountApi mastodonUserAccountApi}): _mastodonSettingsApi = mastodonUserAccountApi;

  Future<List<MastodonUserAccount>> getAll() async {
    List<dynamic> apiResult = (await _mastodonSettingsApi.getAll()).data['data'];
    return apiResult.map((json) => MastodonUserAccount.fromJson(json)).toList();
  }

  Future<bool> add(MastodonUserAccount setting) async {
    final apiResult = (await _mastodonSettingsApi.add(setting)).data;
    if(!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<bool> test(MastodonUserAccount setting) async {
    final apiResult = (await _mastodonSettingsApi.test(setting)).data;
    if(!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<bool> delete(MastodonUserAccount setting) async {
    final apiResult = (await _mastodonSettingsApi.delete(setting)).data;
    if(!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<bool> disable(MastodonUserAccount setting) async {
    final apiResult = (await _mastodonSettingsApi.disable(setting)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<bool> activate(MastodonUserAccount setting) async {
    final apiResult = (await _mastodonSettingsApi.activate(setting)).data;
    if(!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }
}