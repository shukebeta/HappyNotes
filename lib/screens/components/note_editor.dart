import 'package:flutter/material.dart';
import 'dart:math';

import 'package:happy_notes/utils/happy_notes_prompts.dart';

class NoteEditor extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;
  final bool isPrivate;
  final ValueChanged<bool> onPrivateChanged;

  const NoteEditor({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.isEditing,
    required this.isPrivate,
    required this.onPrivateChanged,
  }) : super(key: key);


  @override

  _NoteEditorState createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  late String prompt;

  @override

  void initState() {
    super.initState();
    prompt = HappyNotesPrompts.getRandom(widget.isPrivate);
    widget.focusNode.addListener(_onFocusChange);
  }


  @override

  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      setState(() {
        prompt = HappyNotesPrompts.getRandom(widget.isPrivate);
      });
    }
  }


  @override

  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.isEditing
              ? TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: TextInputType.multiline,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: prompt,
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: widget.isPrivate ? Colors.blue : Colors.green,
                  width: 2.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: widget.isPrivate ? Colors.blueAccent : Colors.greenAccent,
                  width: 2.0,
                ),
              ),
            ),
          )
              : SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                widget.controller.text,
                style: const TextStyle(fontSize: 16.0),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Switch(
              value: widget.isPrivate,
              onChanged: widget.isEditing ? widget.onPrivateChanged : null,
            ),
            Text(widget.isPrivate ? 'Private on' : 'Private off'),
          ],
        ),
      ],
    );
  }
}
