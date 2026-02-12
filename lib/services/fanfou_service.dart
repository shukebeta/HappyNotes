import 'dart:math';

import 'package:happy_notes/entities/fanfou_user_account.dart';
import 'package:happy_notes/services/fanfou_user_account_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_config.dart';
import 'seq_logger.dart';

class FanfouService {
  final FanfouUserAccountService _fanfouUserAccountService;

  FanfouService({
    required FanfouUserAccountService fanfouUserAccountService,
  }) : _fanfouUserAccountService = fanfouUserAccountService;

  String? _state;

  /// Start OAuth 1.0a authorization flow
  /// Returns the list of Fanfou accounts after successful authorization
  Future<List<FanfouUserAccount>> authorize(
    String consumerKey,
    String consumerSecret,
    int syncType,
  ) async {
    // Step 1: Generate state for CSRF protection
    _state = Random.secure().nextInt(1000000).toString();

    // Step 2: Set state in backend (for callback validation)
    await _fanfouUserAccountService.setState(_state!);

    // Step 3: Build authorization URL (backend will handle OAuth flow)
    // Fanfou uses OAuth 1.0a which requires request token first
    // The backend handles this complexity and returns the auth URL
    final authUrl = Uri.parse('${AppConfig.apiBaseUrl}/fanfouAuth/authorize')
        .replace(queryParameters: {
      'consumer_key': consumerKey,
      'consumer_secret': consumerSecret,
      'state': _state!,
    });

    // Step 4: Launch browser for user authorization
    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch $authUrl');
    }

    // Step 5: Wait for OAuth completion (polling)
    return await _waitForAuthorization();
  }

  /// Poll for authorization completion
  Future<List<FanfouUserAccount>> _waitForAuthorization() async {
    int attempts = 0;
    final maxAttempts = 60; // 2 minutes total (60 * 2 seconds)

    while (attempts < maxAttempts) {
      final userList = await _fanfouUserAccountService.getAll();

      // Check if any account was created (username changed from "Pending")
      if (userList.any((account) => account.username != 'Pending')) {
        SeqLogger.info('Fanfou authorization completed successfully');
        return userList;
      }

      SeqLogger.info('Waiting for Fanfou authorization completion...');
      await Future.delayed(const Duration(seconds: 2));
      attempts++;
    }

    throw Exception('Fanfou authorization timed out. Please try again.');
  }
}
