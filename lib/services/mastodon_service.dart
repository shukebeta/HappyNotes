import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'dart:convert';

class MastodonService {
  final String clientName = 'YourAppName';
  final String clientScopes = 'read write follow';
  String? instanceUrl;
  String? accessToken;

  Future<void> authorize(String instanceUrl) async {
    this.instanceUrl = instanceUrl;

    // Step 1: Register the application
    final response = await http.post(
      Uri.parse('$instanceUrl/api/v1/apps'),
      body: {
        'client_name': clientName,
        'redirect_uris': 'urn:ietf:wg:oauth:2.0:oob',
        'scopes': clientScopes,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to register app');
    }

    final appData = json.decode(response.body);
    final clientId = appData['client_id'];
    final clientSecret = appData['client_secret'];

    // Step 2: Get authorization code
    final authUrl = Uri.parse('$instanceUrl/oauth/authorize').replace(queryParameters: {
      'client_id': clientId,
      'response_type': 'code',
      'redirect_uri': 'urn:ietf:wg:oauth:2.0:oob',
      'scope': clientScopes,
    });

    final result = await FlutterWebAuth.authenticate(
      url: authUrl.toString(),
      callbackUrlScheme: "myapp",
    );

    final code = Uri.parse(result).queryParameters['code'];

    // Step 3: Exchange authorization code for access token
    final tokenResponse = await http.post(
      Uri.parse('$instanceUrl/oauth/token'),
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': 'urn:ietf:wg:oauth:2.0:oob',
      },
    );

    if (tokenResponse.statusCode != 200) {
      throw Exception('Failed to get access token');
    }

    final tokenData = json.decode(tokenResponse.body);
    accessToken = tokenData['access_token'];
  }

  Future<void> postStatus(String content) async {
    if (accessToken == null || instanceUrl == null) {
      throw Exception('Not authorized. Call authorize() first.');
    }

    final response = await http.post(
      Uri.parse('$instanceUrl/api/v1/statuses'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: json.encode({'status': content}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to post status');
    }
  }
}

class MastodonAuthScreen extends StatefulWidget {
  const MastodonAuthScreen({super.key});

  @override
  MastodonAuthScreenState createState() => MastodonAuthScreenState();
}

class MastodonAuthScreenState extends State<MastodonAuthScreen> {
  final MastodonService _mastodonService = MastodonService();
  final TextEditingController _instanceController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  bool _isAuthorized = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mastodon Auth')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _instanceController,
              decoration: const InputDecoration(labelText: 'Mastodon Instance URL'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _mastodonService.authorize(_instanceController.text);
                  setState(() => _isAuthorized = true);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Authorization failed: $e')),
                  );
                }
              },
              child: const Text('Authorize'),
            ),
            if (_isAuthorized) ...[
              TextField(
                controller: _statusController,
                decoration: const InputDecoration(labelText: 'Status to post'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await _mastodonService.postStatus(_statusController.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Status posted successfully')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to post status: $e')),
                    );
                  }
                },
                child: const Text('Post Status'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}