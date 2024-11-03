import 'package:dio/dio.dart';
import '../app_config.dart';
import '../dio_client.dart';
import '../entities/mastodon_application.dart';

class MastodonApplicationApi {
  static final Dio _dio = DioClient.getInstance();
 
  Future<Response> createApplication(String instanceUrl) async {
    // register an application on the instance
    return await _dio.post('$instanceUrl/api/v1/apps', data: {
      'client_name': 'Happy Notes',
      'redirect_uris': AppConfig.mastodonRedirectUri(instanceUrl),
      'scopes': 'read write follow',
      'website': 'https://happynotes.shukebeta.com'
    });
  }
  
  Future<Response> get(String instanceUrl) async {
    return await _dio.get('/mastodonApplication/get', queryParameters: {'instanceUrl': instanceUrl});
  }

  Future<Response> save(MastodonApplication app) async {
    return await _dio.post('/mastodonApplication/save', data: app.toJson());
  }
}