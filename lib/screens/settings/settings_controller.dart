import 'package:happy_notes/services/account_service.dart';

class SettingsController {
  final AccountService _accountService;

  SettingsController({required AccountService accountService}): _accountService = accountService;

  Future<void> logout () async {
    await _accountService.logout();
  }

}
