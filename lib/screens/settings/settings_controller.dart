import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:happy_notes/services/account_service.dart';
import 'package:happy_notes/services/user_settings_service.dart';

import '../../utils/util.dart';

class SettingsController {
  final AccountService _accountService;
  final UserSettingsService _userSettingsService;

  SettingsController({required AccountService accountService, required UserSettingsService userSettingsService})
      : _accountService = accountService,
        _userSettingsService = userSettingsService;

  Future<void> save(BuildContext context, String settingName, String settingValue) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      final result = await _userSettingsService.upsert(settingName, settingValue);
    } catch (e) {
      Util.showError(scaffoldContext, e.toString());
    }
  }

  Future<void> logout() async {
    await _accountService.logout();
  }
}
