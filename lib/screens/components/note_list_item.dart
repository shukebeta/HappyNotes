import 'package:flutter/material.dart';

import '../../entities/note.dart';

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap; // onDoubleTap callback is optional

  const NoteListItem({
    Key? key,
    required this.note,
    required this.onTap,
    this.onDoubleTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap, // Call onDoubleTap callback when double-tapped
      child: Container(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 0),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: note.isLong ? '${note.content}...   ' : note.content,
                      style: TextStyle(
                        fontStyle: note.isPrivate ? FontStyle.italic : FontStyle.normal,
                        fontSize: 20,
                        height: 1.6,
                        color: Colors.black,
                      ),
                      children: note.isLong
                          ? [
                        const TextSpan(
                          text: 'more',
                          style: TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        )
                      ]
                          : [],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
