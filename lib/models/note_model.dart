import 'package:flutter/material.dart';

class NoteModel extends ChangeNotifier {
  bool _isPrivate;
  bool _isMarkdown;
  String? _initialTag;

  NoteModel({
    bool isPrivate = true,
    bool isMarkdown = false,
    String? initialTag,
  })  : _isPrivate = isPrivate,
        _isMarkdown = isMarkdown,
        _initialTag = initialTag;

  bool get isPrivate => _isPrivate;
  bool get isMarkdown => _isMarkdown;
  String? get initialTag => _initialTag;

  set isPrivate(bool value) {
    _isPrivate = value;
    notifyListeners();
  }

  set isMarkdown(bool value) {
    _isMarkdown = value;
    notifyListeners();
  }

  set initialTag(String? value) {
    _initialTag = value;
    notifyListeners();
  }

  void resetInitialTag() {
    _initialTag = null;
    notifyListeners();
  }
}