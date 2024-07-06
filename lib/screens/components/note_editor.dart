import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/utils/happy_notes_prompts.dart';
import '../../models/note_model.dart';

class NoteEditor extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isEditing;

  const NoteEditor({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.isEditing,
  }) : super(key: key);

  @override
  NoteEditorState createState() => NoteEditorState();
}

class NoteEditorState extends State<NoteEditor> {
  late String prompt;

  @override
  void initState() {
    super.initState();
    final noteModel = context.read<NoteModel>();
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
        final noteModel = context.read<NoteModel>();
        prompt = HappyNotesPrompts.getRandom(noteModel.isPrivate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: widget.isEditing
              ? _buildEditor()
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
            Consumer<NoteModel>(
              builder: (context, noteModel, child) {
                return GestureDetector(
                  onTap: widget.isEditing
                      ? () {
                          noteModel.isPrivate = !noteModel.isPrivate;
                        }
                      : null,
                  child: Row(
                    children: [
                      const Text('Private'),
                      Switch(
                        value: noteModel.isPrivate,
                        onChanged: widget.isEditing
                            ? (value) {
                                noteModel.isPrivate = value;
                              }
                            : null,
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
                  onTap: widget.isEditing
                      ? () {
                          noteModel.isMarkdown = !noteModel.isMarkdown;
                        }
                      : null,
                  child: Row(
                    children: [
                      const Text('Markdown'),
                      Switch(
                        value: noteModel.isMarkdown,
                        onChanged: widget.isEditing
                            ? (value) {
                                noteModel.isMarkdown = value;
                              }
                            : null,
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
