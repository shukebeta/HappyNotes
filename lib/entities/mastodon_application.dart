class MastodonApplication {
  int? id;
  final String instanceUrl;
  final int applicationId;
  final String clientId;
  final String clientSecret;
  final String redirectUri;
  final String scopes;
  final String name;
  final String website;
  int? createAt;
  int? updateAt;
  int? maxTootChars = 500;

  MastodonApplication({
    this.id,
    required this.instanceUrl,
    required this.applicationId,
    required this.clientId,
    required this.clientSecret,
    required this.redirectUri,
    required this.scopes,
    required this.name,
    required this.website,
    this.createAt,
    this.updateAt,
    this.maxTootChars,
  });

  factory MastodonApplication.fromJson(Map<String, dynamic> json) {
    return MastodonApplication(
      id: json['id'],
      instanceUrl: json['instanceUrl'],
      applicationId: json['applicationId'],
      clientId: json['clientId'],
      clientSecret: json['clientSecret'],
      maxTootChars: json['maxTootChars'],
      redirectUri: json['redirectUri'],
      scopes: json['scopes'],
      name: json['name'],
      website: json['website'],
      createAt: json['createAt'],
      updateAt: json['updateAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['instanceUrl'] = instanceUrl;
    data['applicationId'] = applicationId;
    data['clientId'] = clientId;
    data['clientSecret'] = clientSecret;
    data['maxTootChars'] = maxTootChars;
    data['redirectUri'] = redirectUri;
    data['scopes'] = scopes;
    data['name'] = name;
    data['website'] = website;
    data['createAt'] = createAt;
    data['updateAt'] = updateAt;
    return data;
  }
}
