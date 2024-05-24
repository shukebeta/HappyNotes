import 'package:flutter/material.dart';

class NoteEditor extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: isEditing
              ? TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Write your note here...',
                    border: OutlineInputBorder(),
                  ),
                )
              : SingleChildScrollView(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      controller.text,
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 16.0),
        Row(
          children: [
            const Text('Private Note'),
            Switch(
              value: isPrivate,
              onChanged: isEditing ? onPrivateChanged : null,
            ),
          ],
        ),
      ],
    );
  }
}
