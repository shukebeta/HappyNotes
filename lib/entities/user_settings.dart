class UserSettings {
  final int id;
  final int userId;
  final String settingName;
  String settingValue;

  UserSettings({
    required this.id,
    required this.userId,
    required this.settingName,
    required this.settingValue,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      id: json['id'],
      userId: json['userId'],
      settingName: json['settingName'],
      settingValue: json['settingValue'],
    );
  }
}
