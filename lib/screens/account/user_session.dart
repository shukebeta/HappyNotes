
import 'package:flutter/material.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  static final routeObserver = RouteObserver<ModalRoute>();

  int? id;
  String? email;

  factory UserSession() {
    return _instance;
  }

  UserSession._internal();
}

