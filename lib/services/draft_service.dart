import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Draft {
  final String content;
  final bool isPrivate;
  final bool isMarkdown;
  final DateTime savedAt;

  Draft({
    required this.content,
    required this.isPrivate,
    required this.isMarkdown,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() => {
    'content': content,
    'isPrivate': isPrivate,
    'isMarkdown': isMarkdown,
    'savedAt': savedAt.toIso8601String(),
  };

  factory Draft.fromJson(Map<String, dynamic> json) => Draft(
    content: json['content'] as String,
    isPrivate: json['isPrivate'] as bool,
    isMarkdown: json['isMarkdown'] as bool,
    savedAt: DateTime.parse(json['savedAt'] as String),
  );
}

class DraftService extends ChangeNotifier {
  static const String _draftKey = 'happy_notes_draft';

  Future<void> saveDraft({
    required String content,
    required bool isPrivate,
    required bool isMarkdown,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final draft = Draft(
      content: content,
      isPrivate: isPrivate,
      isMarkdown: isMarkdown,
      savedAt: DateTime.now(),
    );
    await prefs.setString(_draftKey, jsonEncode(draft.toJson()));
  }

  Future<Draft?> loadDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draftJson = prefs.getString(_draftKey);
    if (draftJson == null) return null;
    try {
      return Draft.fromJson(jsonDecode(draftJson) as Map<String, dynamic>);
    } catch (_) {
      await clearDraft();
      return null;
    }
  }

  Future<void> clearDraft() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
    notifyListeners();
  }
}

