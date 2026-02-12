import 'package:flutter/material.dart';
import 'package:happy_notes/apis/fanfou_user_account_api.dart';
import 'package:happy_notes/entities/fanfou_user_account.dart';

import '../../services/fanfou_user_account_service.dart';
import '../../utils/util.dart';

class FanfouSyncSettingsController {
  final FanfouUserAccountService _fanfouUserAccountService;
  bool isLoading = false;
  List<FanfouUserAccount> fanfouAccounts = [];

  FanfouSyncSettingsController({required FanfouUserAccountService fanfouUserAccountService})
      : _fanfouUserAccountService = fanfouUserAccountService;

  Future<void> getFanfouAccounts(BuildContext context) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      isLoading = true;
      fanfouAccounts = await _fanfouUserAccountService.getAll();
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    } finally {
      isLoading = false;
    }
  }

  Future<bool> addFanfouAccount(PostFanfouAccountRequest request) async {
    return await _fanfouUserAccountService.add(request);
  }

  Future<void> nextSyncType(BuildContext context, FanfouUserAccount account) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      await _fanfouUserAccountService.nextSyncType(account);
    } catch (error) {
      Util.showError(scaffoldContext, "Failed to update sync type: $error");
    }
  }

  Future<bool> activateFanfouAccount(FanfouUserAccount account) async {
    return await _fanfouUserAccountService.activate(account);
  }

  Future<bool> disableFanfouAccount(FanfouUserAccount account) async {
    return await _fanfouUserAccountService.disable(account);
  }

  Future<bool> deleteFanfouAccount(FanfouUserAccount account) async {
    return await _fanfouUserAccountService.delete(account);
  }
}
