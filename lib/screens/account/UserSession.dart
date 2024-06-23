class UserSession {
  static final UserSession _instance = UserSession._internal();

  int? id;
  String? email;

  factory UserSession() {
    return _instance;
  }

  UserSession._internal();
}

