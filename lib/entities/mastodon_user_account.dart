class MastodonUserAccount {
  int? id;
  int? userId;
  final int? status;
  final int syncType;
  final String? instanceUrl;
  final String? scope;

  String accessToken;
  String tokenType;
  String? statusText = '';

  String? get syncTypeText {
    switch (syncType) {
      case 1:
        return 'All';
      case 2:
        return 'Public note only';
      case 3:
        return 'Note with tag Mastodon only';
      default:
        return 'Unknown';
    }
  }

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
    required this.syncType,
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
      syncType: json['syncType'],
      statusText: json['statusText'],
    );
  }
}
