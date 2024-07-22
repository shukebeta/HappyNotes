import 'package:flutter/material.dart';
import 'package:happy_notes/entities/user_settings.dart';


class UserSession {
  static final UserSession _instance = UserSession._internal();
  static final routeObserver = RouteObserver<ModalRoute>();

  int? id;
  String? email;
  List<UserSettings>? userSettings;

  factory UserSession() {
    return _instance;
  }

  UserSession._internal();
  String? settings(String key) {
    if (userSettings != null) {
      try {
        final settings = userSettings!.firstWhere((w) => w.settingName == key);
        return settings.settingValue;
      } catch (e){
        // did nothing;
      }
    }
    return null;
  }
}

