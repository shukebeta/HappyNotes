import 'package:flutter/material.dart';

class NoteModel with ChangeNotifier {
  bool _isPrivate;
  bool _isMarkdown;

  NoteModel({bool isPrivate = true, bool isMarkdown = false})
      : _isPrivate = isPrivate,
        _isMarkdown = isMarkdown;

  bool get isPrivate => _isPrivate;

  set isPrivate(bool value) {
    if (_isPrivate != value) {
      _isPrivate = value;
      notifyListeners(); // Notify listeners about the change
    }
  }

  bool get isMarkdown => _isMarkdown;

  set isMarkdown(bool value) {
    if (_isMarkdown != value) {
      _isMarkdown = value;
      notifyListeners(); // Notify listeners about the change
    }
  }
}
