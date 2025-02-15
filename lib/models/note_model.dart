import 'package:flutter/material.dart';

class NoteModel with ChangeNotifier {
  bool _isPrivate;
  bool _isMarkdown;
  String _initialContent;
  String _content;
  String _publishDateTime;
  late FocusNode focusNode;

  NoteModel(
      {bool isPrivate = true,
      bool isMarkdown = false,
      String initialTag = '',
      String content = '',
      String publishDateTime = ''})
      : _isPrivate = isPrivate,
        _isMarkdown = isMarkdown,
        _initialContent = initialTag,
        _content = content,
        _publishDateTime = publishDateTime {
    focusNode = FocusNode();
  }

  bool isPasting = false;

  void setPasting(bool value) {
    if (isPasting != value) {
      isPasting = value;
      notifyListeners();
    }
  }

  bool isUploading = false;

  void setUploading(bool value) {
    if (isUploading != value) {
      isUploading = value;
      notifyListeners();
    }
  }

  bool get isPrivate => _isPrivate;

  bool get isMarkdown => _isMarkdown;

  String get initialContent => _initialContent;

  String get content => _content;

  String get publishDateTime => _publishDateTime;

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

  set initialContent(String value) {
    // here content can be a tag, or a note id
    var content = value.startsWith('@') ? '$value ' : '#$value ';
    if (_initialContent != content) {
      _initialContent = content;
      notifyListeners();
    }
  }

  set content(String value) {
    if (_content != value) {
      _content = value;
      notifyListeners();
    }
  }

  set publishDateTime(String value) {
    if (_publishDateTime != value) {
      _publishDateTime = value;
    }
    notifyListeners();
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
