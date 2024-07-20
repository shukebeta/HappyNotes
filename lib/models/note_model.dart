import 'package:flutter/material.dart';

class NoteModel with ChangeNotifier {
  bool _isPrivate;
  bool _isMarkdown;
  String _initialTag;
  String _content;

  NoteModel({bool isPrivate = true, bool isMarkdown = false, String initialTag = '', String content = ''})
      : _isPrivate = isPrivate,
        _isMarkdown = isMarkdown,
        _initialTag = initialTag,
        _content = content;

  bool get isPrivate => _isPrivate;

  bool get isMarkdown => _isMarkdown;

  String get initialTag => _initialTag;

  String get content => _content;

  set isPrivate(bool value) {
    _isPrivate = value;
    notifyListeners();
  }

  set isMarkdown(bool value) {
    _isMarkdown = value;
    notifyListeners();
  }

  set initialTag(String value) {
    _initialTag = value;
    notifyListeners();
  }

  void resetInitialTag() {
    _initialTag = '';
    notifyListeners();
  }

  void setContent(String value) {
    // Add this method
    _content = value;
    notifyListeners();
  }
}
