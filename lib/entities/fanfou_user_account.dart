class FanfouUserAccount {
  int? id;
  int? userId;
  final int syncType;
  final int? status;

  /// The authorizing user's Fanfou id / screen name.
  final String? fanfouUserId;

  String? statusText = '';

  String? get syncTypeText {
    switch (syncType) {
      case 1:
        return 'All';
      case 2:
        return 'Public note only';
      case 3:
        return 'Note with tag Fanfou only';
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

  FanfouUserAccount({
    this.id,
    this.userId,
    required this.syncType,
    this.status,
    this.fanfouUserId,
    this.statusText,
  });

  factory FanfouUserAccount.fromJson(Map<String, dynamic> json) {
    return FanfouUserAccount(
      id: json['id'],
      userId: json['userId'],
      syncType: json['syncType'],
      status: json['status'],
      fanfouUserId: json['fanfouUserId'],
      statusText: json['statusText'],
    );
  }
}
