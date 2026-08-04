import 'package:happy_notes/exceptions/api_exception.dart';
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

  /// Kicks off the OAuth flow and returns the Fanfou authorize URL to open.
  Future<String> requestToken() async {
    final apiResult = (await _fanfouUserAccountApi.requestToken()).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return apiResult['data'] as String;
  }

  Future<void> nextSyncType() async {
    final apiResult = (await _fanfouUserAccountApi.nextSyncType()).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
  }

  Future<bool> activate() async {
    final apiResult = (await _fanfouUserAccountApi.activate()).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<bool> disable() async {
    final apiResult = (await _fanfouUserAccountApi.disable()).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }

  Future<bool> delete() async {
    final apiResult = (await _fanfouUserAccountApi.delete()).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return true;
  }
}
