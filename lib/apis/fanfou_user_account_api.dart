import 'package:dio/dio.dart';
import 'package:happy_notes/entities/fanfou_user_account.dart';
import '../dio_client.dart';

class FanfouUserAccountApi {
  static final Dio _dio = DioClient.getInstance();

  Future<Response> getAll() async {
    return await _dio.get('/FanfouAccounts');
  }

  Future<Response> add(PostFanfouAccountRequest request) async {
    return await _dio.post('/FanfouAccounts', data: request.toJson());
  }

  Future<Response> update(int id, PutFanfouAccountRequest request) async {
    return await _dio.put('/FanfouAccounts/$id', data: request.toJson());
  }

  Future<Response> activate(FanfouUserAccount account) async {
    var data = _getPostData(account);
    return await _dio.post('/FanfouAccounts/activate', data: data);
  }

  Future<Response> disable(FanfouUserAccount account) async {
    var data = _getPostData(account);
    return await _dio.post('/FanfouAccounts/disable', data: data);
  }

  Future<Response> delete(FanfouUserAccount account) async {
    var data = _getPostData(account);
    return await _dio.delete('/FanfouAccounts/${account.id}', data: data);
  }

  Future<Response> setState(String state) async {
    final options = Options(
      headers: {'X-State': state},
    );
    return await _dio.post('/FanfouAuth/setState', options: options);
  }

  Map<String, Object?> _getPostData(FanfouUserAccount account) {
    return {
      'userId': account.userId,
      'username': account.username,
      'consumerKey': account.consumerKey,
      'consumerSecret': account.consumerSecret,
      'syncType': account.syncType,
    };
  }
}

class PostFanfouAccountRequest {
  final String consumerKey;
  final String consumerSecret;
  final int syncType;

  PostFanfouAccountRequest({
    required this.consumerKey,
    required this.consumerSecret,
    this.syncType = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'consumerKey': consumerKey,
      'consumerSecret': consumerSecret,
      'syncType': syncType,
    };
  }
}

class PutFanfouAccountRequest {
  final int syncType;

  PutFanfouAccountRequest({required this.syncType});

  Map<String, dynamic> toJson() {
    return {'syncType': syncType};
  }
}
