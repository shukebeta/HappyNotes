import 'package:happy_notes/common/fanfou_sync_type.dart';

class FanfouUserAccount {
  int? id;
  int? userId;
  String username;
  String? consumerKey;
  String? consumerSecret;
  int syncType;
  int status;
  int createdAt;

  FanfouUserAccount({
    this.id,
    this.userId,
    this.username = '',
    this.consumerKey,
    this.consumerSecret,
    this.syncType = 1,
    this.status = 2,
    this.createdAt = 0,
  });

  FanfouUserAccount.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        userId = json['userId'],
        username = json['username'] ?? '',
        consumerKey = json['consumerKey'],
        consumerSecret = json['consumerSecret'],
        syncType = json['syncType'] ?? 1,
        status = json['status'] ?? 2,
        createdAt = json['createdAt'] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'syncType': syncType,
      'status': status,
      'createdAt': createdAt,
    };
  }

  // Getters for UI
  bool get isActive => status == 1;
  bool get isDisabled => status == 2;
  bool get isError => status == 3;

  // Status text
  String get statusText {
    switch (status) {
      case 1:
        return 'Active';
      case 2:
        return 'Disabled';
      case 3:
        return 'Error';
      default:
        return 'Unknown';
    }
  }

  // Sync type text
  String get syncTypeText {
    return FanfouSyncType.fromInt(syncType).label;
  }

  FanfouSyncType get syncTypeEnum {
    return FanfouSyncType.fromInt(syncType);
  }
}
