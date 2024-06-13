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
                  decoration: InputDecoration(
                    hintText: 'Write your ${isPrivate ? 'private' : 'public'} note here...',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isPrivate ? Colors.blue : Colors.green, // Set border color based on isPrivate
                        width: 2.0, // Set the border width
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: isPrivate ? Colors.blueAccent : Colors.greenAccent, // Set focused border color
                        width: 2.0, // Set the focused border width
                      ),
                    ),
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
        const SizedBox(height: 8.0),
        Row(
          children: [
            Switch(
              value: isPrivate,
              onChanged: isEditing ? onPrivateChanged : null,
            ),
            Text(isPrivate ? 'Private on' : 'Private off'),
          ],
        ),
      ],
    );
  }
}
