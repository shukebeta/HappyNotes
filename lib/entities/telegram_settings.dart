class TelegramSettings {
  int? id;
  int? userId;
  final int syncType;
  final String syncValue;
  final String channelId ;
  String? encryptedToken;
  String? tokenRemark;
  String? channelName;

  TelegramSettings({
    this.id,
    this.userId,
    required this.syncType,
    required this.syncValue,
    required this.channelId,
    this.encryptedToken,
    this.tokenRemark,
    this.channelName,
  });

  factory TelegramSettings.fromJson(Map<String, dynamic> json) {
    return TelegramSettings(
      id: json['id'],
      userId: json['userId'],
      syncType: json['syncType'],
      syncValue: json['syncValue'],
      encryptedToken: json['encryptedToken'],
      tokenRemark: json['tokenRemark'],
      channelId: json['channelId'],
      channelName: json['channelRemark'],
    );
  }
}
