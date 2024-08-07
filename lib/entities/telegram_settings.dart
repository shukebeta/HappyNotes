class TelegramSettings {
  final int id;
  final int userId;
  final int syncType;
  final String syncValue;
  final String channelId ;
  String? encryptedToken;
  String? tokenRemark;
  String? channelName;

  TelegramSettings({
    required this.id,
    required this.userId,
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
      syncValue: json['settingValue'],
      encryptedToken: json['encryptedToken'],
      tokenRemark: json['tokenRemark'],
      channelId: json['channelId'],
      channelName: json['channelRemark'],
    );
  }
}
