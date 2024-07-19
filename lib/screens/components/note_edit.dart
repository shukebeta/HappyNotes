// note_edit.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/utils/happy_notes_prompts.dart';
import '../../models/note_model.dart';

class NoteEdit extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? initialTag;

  const NoteEdit({
    Key? key,
    required this.controller,
    required this.focusNode,
    this.initialTag,
  }) : super(key: key);

  @override
  NoteEditState createState() => NoteEditState();
}

class NoteEditState extends State<NoteEdit> {
  late String prompt;

  @override
  void initState() {
    super.initState();
    final noteModel = context.read<NoteModel>();
    if (widget.initialTag != null) {
      widget.controller.text = '#${widget.initialTag!}\n${widget.controller.text}';
    }
    prompt = HappyNotesPrompts.getRandom(noteModel.isPrivate);
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _buildEditor(),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Consumer<NoteModel>(
              builder: (context, noteModel, child) {
                return GestureDetector(
                  onTap: () {
                    noteModel.isPrivate = !noteModel.isPrivate;
                  },
                  child: Row(
                    children: [
                      const Text('Private'),
                      Switch(
                        value: noteModel.isPrivate,
                        onChanged: (value) {
                          noteModel.isPrivate = value;
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 24.0),
            Consumer<NoteModel>(
              builder: (context, noteModel, child) {
                return GestureDetector(
                  onTap: () {
                    noteModel.isMarkdown = !noteModel.isMarkdown;
                  },
                  child: Row(
                    children: [
                      const Text('Markdown'),
                      Switch(
                        value: noteModel.isMarkdown,
                        onChanged: (value) {
                          noteModel.isMarkdown = value;
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  TextField _buildEditor() {
    return TextField(
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
            color: context.read<NoteModel>().isPrivate ? Colors.blue : Colors.green,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: context.read<NoteModel>().isPrivate ? Colors.blueAccent : Colors.greenAccent,
            width: 2.0,
          ),
        ),
      ),
    );
  }
}
