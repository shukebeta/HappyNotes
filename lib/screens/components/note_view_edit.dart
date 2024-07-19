import 'package:flutter/material.dart';
import 'note_view.dart';
import 'note_edit.dart';

class NoteViewEdit extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;
  final bool isMarkdown;
  final String? initialTag;

  const NoteViewEdit({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.isEditing,
    required this.isMarkdown,
    this.initialTag,
  }) : super(key: key);

  @override
  NoteViewEditState createState() => NoteViewEditState();
}

class NoteViewEditState extends State<NoteViewEdit> {
  @override
  Widget build(BuildContext context) {
    return widget.isEditing
        ? NoteEdit(
      controller: widget.controller,
      focusNode: widget.focusNode,
      initialTag: widget.initialTag,
    )
        : NoteView(
      controller: widget.controller,
      isMarkdown: widget.isMarkdown,
    );
  }
}
