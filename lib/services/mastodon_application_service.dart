import '../apis/mastodon_application_api.dart';
import '../entities/mastodon_application.dart';
import '../exceptions/api_exception.dart';

class MastodonApplicationService {
  final String clientName = 'HappyNotes';
  final String clientScopes = 'read write push';
  final MastodonApplicationApi _mastodonApplicationApi;

  MastodonApplicationService({required MastodonApplicationApi mastodonApplicationApi})
      : _mastodonApplicationApi = mastodonApplicationApi;

  late String redirectUri;
  String? instanceUrl;
  String? accessToken;

  Future<MastodonApplication> createApplication(String instanceUrl) async {
    var response = await _mastodonApplicationApi.createApplication(instanceUrl);
    var data = response.data;
    var mastodonApplication = MastodonApplication(
      instanceUrl: instanceUrl,
      applicationId: int.parse(data['id']),
      clientId: data['client_id'],
      clientSecret: data['client_secret'],
      redirectUri: data['redirect_uris'][0],
      scopes: data['scopes'].join(' '),
      name: data['name'],
      website: data['website'],
    );
    var apiResult = (await _mastodonApplicationApi.save(mastodonApplication)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return mastodonApplication;
  }

  Future<MastodonApplication?> get(String instanceUrl) async {
    var apiResult = (await _mastodonApplicationApi.get(instanceUrl)).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    var app = apiResult['data'];
    if (app == null) return app;
    return MastodonApplication.fromJson(app);
  }
}
