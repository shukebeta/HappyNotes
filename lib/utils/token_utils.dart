import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../exceptions/custom_exception.dart';

class TokenUtils {

  Future<Map<String, dynamic>> decodeToken(String token) async {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw CustomException('Invalid token');
    }

    var jwt = JWT.decode(token);
    if (jwt.payload is! Map<String, dynamic>) {
      throw CustomException('Invalid payload');
    }

    return jwt.payload;
  }

  Future<Duration> getTokenRemainingTime(String token) async {
    final payload = await decodeToken(token);

    if (!payload.containsKey('exp')) {
      throw CustomException('Token does not contain an expiration date');
    }

    final exp = payload['exp'];
    final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    final currentTime = DateTime.now();

    return expiryDate.difference(currentTime);
  }
}
