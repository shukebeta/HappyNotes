import 'package:dio/dio.dart';
import '../dependency_injection.dart';
import '../services/account_service.dart';

class AuthInterceptor extends Interceptor {
  final accountService = locator<AccountService>();
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Check if the request requires authentication
    if (options.headers.containsKey('AllowAnonymous')) {
      return handler.next(options);
    }

    final token = await accountService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }
}
