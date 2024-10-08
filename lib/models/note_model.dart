import 'package:flutter/material.dart';

class NoteModel with ChangeNotifier {
  bool _isPrivate;
  bool _isMarkdown;
  String _initialTag;
  String _content;
  late FocusNode focusNode;

  NoteModel({
    bool isPrivate = true,
    bool isMarkdown = false,
    String initialTag = '',
    String content = ''
  })  : _isPrivate = isPrivate,
        _isMarkdown = isMarkdown,
        _initialTag = initialTag,
        _content = content {
    focusNode = FocusNode();
  }

  bool get isPrivate => _isPrivate;
  bool get isMarkdown => _isMarkdown;
  String get initialTag => _initialTag;
  String get content => _content;

  set isPrivate(bool value) {
    if (_isPrivate != value) {
      _isPrivate = value;
      notifyListeners();
    }
  }

  set isMarkdown(bool value) {
    if (_isMarkdown != value) {
      _isMarkdown = value;
      notifyListeners();
    }
  }

  set initialTag(String value) {
    if (_initialTag != value) {
      _initialTag = value;
      notifyListeners();
    }
  }

  set content(String value) {
    if (_content != value) {
      _content = value;
      notifyListeners();
    }
  }

  void requestFocus() {
    focusNode.requestFocus();
    notifyListeners();
  }

  void unfocus() {
    focusNode.unfocus();
    notifyListeners();
  }

  void togglePrivate() {
    _isPrivate = !_isPrivate;
    notifyListeners();
  }

  void toggleMarkdown() {
    _isMarkdown = !_isMarkdown;
    notifyListeners();
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }
}