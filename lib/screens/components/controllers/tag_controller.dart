import 'dart:async';
import 'package:flutter/material.dart';
import '../tag_list_overlay.dart';
import '../../../services/note_tag_service.dart';
import '../../../models/note_model.dart';

class TagController {
  final NoteTagService noteTagService;
  OverlayEntry? _tagListOverlay;
  Timer? _tagListTimer;

  TagController({required this.noteTagService});

  static const Duration tagListTimerDuration = Duration(milliseconds: 200);

  void handleTextChanged(
      String text, TextSelection selection, NoteModel noteModel, BuildContext context) {
    final cursorPosition = selection.baseOffset;
    if (cursorPosition > 0 && text[cursorPosition - 1] == '#') {
      _tagListTimer?.cancel();
      _tagListTimer = Timer(tagListTimerDuration, () async {
        showTagList(noteModel, text, cursorPosition, context);
      });
    } else {
      _tagListTimer?.cancel();
    }
  }

  void showTagList(
      NoteModel noteModel, String text, int cursorPosition, BuildContext context) {
    if (_tagListOverlay != null) return;

    _tagListOverlay = OverlayEntry(
      builder: (context) => TagListOverlay(
        noteModel: noteModel,
        text: text,
        cursorPosition: cursorPosition,
        onTagSelected: (text, position, tag) {
          handleTagSelection(text, position, tag, noteModel);
          _tagListOverlay?.remove();
          _tagListOverlay = null;
        },
      ),
    );

    Overlay.of(context).insert(_tagListOverlay!);
  }

  void handleTagSelection(
      String text, int cursorPosition, String tag, NoteModel noteModel) {
    String newText;
    int newCursorPosition;
    if (cursorPosition > 0 && text[cursorPosition - 1] == '#') {
      newText =
          '${text.substring(0, cursorPosition)}$tag ${text.substring(cursorPosition)}';
      newCursorPosition = cursorPosition + tag.length + 1;
    } else {
      newText =
          '${text.substring(0, cursorPosition)}#$tag ${text.substring(cursorPosition)}';
      newCursorPosition = cursorPosition + tag.length + 2;
    }
    noteModel.content = newText;
    // Update cursor position via the controller in NoteEdit widget
    noteModel.requestFocus();
  }

  void dispose() {
    _tagListTimer?.cancel();
    _tagListOverlay?.remove();
    _tagListOverlay = null;
  }
}