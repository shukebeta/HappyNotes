import 'dart:convert';

class TokenUtils {

  Future<Map<String, dynamic>> decodeToken(String token) async {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = base64Url.decode(base64Url.normalize(parts[1]));
    final payloadMap = json.decode(utf8.decode(payload));

    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid payload');
    }

    return payloadMap;
  }

  Future<Duration> getTokenRemainingTime(String token) async {
    final payload = await decodeToken(token);

    if (!payload.containsKey('exp')) {
      throw Exception('Token does not contain an expiration date');
    }

    final exp = payload['exp'];
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final currentTime = DateTime.now();

    return expiryDate.difference(currentTime);
  }
}
