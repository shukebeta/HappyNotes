import 'package:flutter/material.dart';
import 'package:happy_notes/entities/fanfou_user_account.dart';

import '../../services/fanfou_user_account_service.dart';
import '../../utils/util.dart';

class FanfouSyncSettingsController {
  final FanfouUserAccountService _fanfouSettingService;
  bool isLoading = false;
  List<FanfouUserAccount> fanfouSettings = [];

  FanfouSyncSettingsController({required FanfouUserAccountService fanfouUserAccountService})
      : _fanfouSettingService = fanfouUserAccountService;

  Future<void> getFanfouSettings(BuildContext context) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      isLoading = true;
      fanfouSettings = await _fanfouSettingService.getAll();
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    } finally {
      isLoading = false;
    }
  }

  Future<void> nextSyncType(BuildContext context) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      await _fanfouSettingService.nextSyncType();
    } catch (error) {
      Util.showError(scaffoldContext, "Test failed: $error");
    }
  }

  Future<bool> activateFanfouSetting() async {
    return await _fanfouSettingService.activate();
  }

  Future<bool> disableFanfouSetting() async {
    return await _fanfouSettingService.disable();
  }

  Future<bool> deleteFanfouSetting() async {
    return await _fanfouSettingService.delete();
  }
}
