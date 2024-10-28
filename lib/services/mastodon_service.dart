import 'dart:math';

import 'package:happy_notes/entities/mastodon_user_account.dart';
import 'package:happy_notes/services/mastodon_user_account_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_config.dart';
import 'mastodon_application_service.dart';

class MastodonService {
  final MastodonApplicationService _mastodonApplicationService;
  final MastodonUserAccountService _mastodonUserAccountService;

  MastodonService(
      {required MastodonApplicationService mastodonApplicationService,
      required MastodonUserAccountService mastodonUserAccountService})
      : _mastodonApplicationService = mastodonApplicationService,
        _mastodonUserAccountService = mastodonUserAccountService;

  late String redirectUri;
  String? instanceUrl;
  String? accessToken;

  Future<List<MastodonUserAccount>> authorize(String instanceUrl) async {
    this.instanceUrl = instanceUrl;

    var application = await _mastodonApplicationService.get(instanceUrl);
    application ??= await _mastodonApplicationService.createApplication(instanceUrl);
    var clientId = application.clientId;
    var state = Random.secure().nextInt(1000000).toString();

    await _mastodonUserAccountService.setState(state);

    // Step 2: Get authorization code
    final authUrl = Uri.parse('$instanceUrl/oauth/authorize').replace(queryParameters: {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': AppConfig.mastodonRedirectUri(instanceUrl),
      'scope': application.scopes,
      'state': state,
    });

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl);
    } else {
      throw Exception('Could not launch $authUrl');
    }
    return await _waitForAuthorization();
  }

  Future<List<MastodonUserAccount>> _waitForAuthorization() async {
    while (true) {
      final userList = await _mastodonUserAccountService.getAll();
      try {
        // if no matching record found, an exception would be thrown
        userList.firstWhere((element) => element.instanceUrl == instanceUrl);
        return userList;
      } catch (e) {
        print("Waiting for authorization...");
      }
      await Future.delayed(const Duration(seconds: 2));
    }

// Future<void> postStatus(String content) async {
//   if (accessToken == null || instanceUrl == null) {
//     throw Exception('Not authorized. Call authorize() first.');
//   }
//
//   final response = await http.post(
//     Uri.parse('$instanceUrl/api/v1/statuses'),
//     headers: {
//       'Authorization': 'Bearer $accessToken',
//       'Content-Type': 'application/json',
//     },
//     body: json.encode({'status': content}),
//   );
//
//   if (response.statusCode != 200) {
//     throw Exception('Failed to post status');
//   }
  }
}
