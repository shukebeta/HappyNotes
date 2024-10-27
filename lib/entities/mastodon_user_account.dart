class MastodonUserAccount {
  int? id;
  int? userId;
  final int? status;
  final String? instanceUrl;
  final String? scope;

  String accessToken;
  String tokenType;
  String? statusText = '';

  bool get isActive {
    return statusText == 'Normal';
  }

  bool get isDisabled {
    return statusText == 'Disabled' || (statusText ?? '').contains('Inactive');
  }

  bool get isTested {
    return statusText == 'Created' || statusText == 'Normal' || statusText == 'Disabled';
  }

  MastodonUserAccount({
    this.id,
    this.userId,
    required this.instanceUrl,
    required this.scope,
    required this.accessToken,
    required this.tokenType,
    this.status,
    this.statusText,
  });

  factory MastodonUserAccount.fromJson(Map<String, dynamic> json) {
    return MastodonUserAccount(
      id: json['id'],
      userId: json['userId'],
      instanceUrl: json['instanceUrl'],
      scope: json['scope'],
      accessToken: json['accessToken'],
      tokenType: json['tokenType'],
      status: json['status'],
      statusText: json['statusText'],
    );
  }
}
