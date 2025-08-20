class ApiException implements Exception {
  final dynamic apiResult;

  ApiException(this.apiResult);

  @override
  String toString() {
    if (apiResult != null && apiResult is Map) {
      final errorCode = apiResult['errorCode'];
      final message = apiResult['message'];
      return '$message ($errorCode)';
    } else {
      return 'ApiException: Invalid API result';
    }
  }
}
