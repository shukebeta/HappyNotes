import 'package:happy_notes/exceptions/api_exception.dart';
import 'package:happy_notes/common/fanfou_sync_type.dart';
import '../apis/fanfou_user_account_api.dart';
import '../entities/fanfou_user_account.dart';

class FanfouUserAccountService {
  final FanfouUserAccountApi _fanfouUserAccountApi;

  FanfouUserAccountService({required FanfouUserAccountApi fanfouUserAccountApi})
      : _fanfouUserAccountApi = fanfouUserAccountApi;

  Future<List<FanfouUserAccount>> getAll() async {
    List<dynamic> apiResult = (await _fanfouUserAccountApi.getAll()).data['data'];
    return apiResult.map((json) => FanfouUserAccount.fromJson(json)).toList();
  }

  Future<bool> add(PostFanfouAccountRequest request) async {
    final apiResult = (await _fanfouUserAccountApi.add(request)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<void> nextSyncType(FanfouUserAccount setting) async {
    final currentSyncType = FanfouSyncType.fromInt(setting.syncType);
    final nextSyncType = currentSyncType.next();

    final request = PutFanfouAccountRequest(syncType: nextSyncType.value);
    final apiResult = (await _fanfouUserAccountApi.update(setting.id!, request)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
  }

  Future<bool> delete(FanfouUserAccount setting) async {
    final apiResult = (await _fanfouUserAccountApi.delete(setting)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<bool> disable(FanfouUserAccount setting) async {
    final apiResult = (await _fanfouUserAccountApi.disable(setting)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<bool> activate(FanfouUserAccount setting) async {
    final apiResult = (await _fanfouUserAccountApi.activate(setting)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<void> setState(String state) async {
    await _fanfouUserAccountApi.setState(state);
  }
}
