import 'package:flutter/material.dart';
import 'package:happy_notes/entities/mastodon_user_account.dart';

import '../../services/mastodon_user_account_service.dart';
import '../../utils/util.dart';

class MastodonSyncSettingsController {
  final MastodonUserAccountService _mastodonSettingService;
  bool isLoading = false;
  List<MastodonUserAccount> mastodonSettings = [];

  MastodonSyncSettingsController({required MastodonUserAccountService mastodonUserAccountService})
      : _mastodonSettingService = mastodonUserAccountService;

  Future<void> getMastodonSettings(BuildContext context) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      isLoading = true;
      mastodonSettings = await _mastodonSettingService.getAll();
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    } finally {
      isLoading = false;
    }
  }

  Future<bool> addMastodonSetting(MastodonUserAccount setting) async {
    return await _mastodonSettingService.add(setting);
  }

  Future<void> nextSyncType(BuildContext context, MastodonUserAccount setting) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      await _mastodonSettingService.nextSyncType(setting);
    } catch (error) {
      Util.showError(scaffoldContext, "Test failed: $error");
    }
  }

  Future<bool> activateMastodonSetting(MastodonUserAccount setting) async {
    return await _mastodonSettingService.activate(setting);
  }

  Future<bool> disableMastodonSetting(MastodonUserAccount setting) async {
    return await _mastodonSettingService.disable(setting);
  }

  Future<bool> deleteMastodonSetting(MastodonUserAccount setting) async {
    return await _mastodonSettingService.delete(setting);
  }
}
