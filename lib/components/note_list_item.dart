import 'package:flutter/material.dart';
import '../../entities/note.dart';

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;

  const NoteListItem({
    Key? key,
    required this.note,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                text: note.isLong ? '${note.content}...   ' : note.content,
                style: TextStyle(
                  fontWeight: note.isPrivate ? FontWeight.w100 : FontWeight.normal,
                  fontSize: 20,
                  color: Colors.black,
                ),
                children: note.isLong
                    ? [
                  const TextSpan(
                    text: 'more',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  )
                ]
                    : [],
              ),
            ),
          ),
          if (note.isPrivate)
            const Icon(
              Icons.lock,
              size: 16.0,
              color: Colors.grey,
            ),
        ],
      ),
      subtitle: Text(
        DateTime.fromMillisecondsSinceEpoch(note.createAt * 1000).toString(),
      ),
      onTap: onTap,
    );
  }
}
