import 'package:happy_notes/dio_interceptors/auth_interceptor.dart';
import 'package:happy_notes/utils/app_logger.dart';
import 'package:dio/dio.dart';

import 'app_config.dart';

class DioClient {
  static Dio? _dio;

  DioClient._internal();

  static Dio getInstance() {
    if (_dio == null) {
      _dio = Dio(); // Create Dio instance if not already created
      _dio!.options.baseUrl = AppConfig.baseUrl;
      _dio!.interceptors.add(LogInterceptor(requestBody: true, responseBody: true)); // Add logging interceptor
      _dio!.interceptors.add(AuthInterceptor());
      _dio!.interceptors.add(InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          options.contentType = 'application/json';
          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          // Handle global response data here if needed
          return handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          // Handle global error here
          // AppLogger.e(e.toString());
          return handler.next(e);
        },
      ));
    }
    return _dio!;
  }
}

