import 'package:flutter/material.dart';
import 'package:happy_notes/screens/account/user_session.dart';
import 'package:happy_notes/typedefs.dart';
import '../../entities/note.dart';
import 'markdown_body_here.dart';
import 'tag_widget.dart'; // Import your TagWidget

class NoteListItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final Function(Note note, String tag)? onTagTap;

  const NoteListItem({
    Key? key,
    required this.note,
    required this.onTap,
    this.onDoubleTap,
    this.onTagTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var author = (note.user == null || note.userId == UserSession().id) ? '' : '${note.user!.username} ';
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Row(
              children: [
                Text(
                  '- ${note.createdTime} $author',
                  style: const TextStyle(
                    fontWeight: FontWeight.w300,
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                ),
                ...[
                  if (note.isPrivate)
                    const Icon(
                      Icons.lock,
                      color: Colors.blueGrey,
                      size: 14,
                    ),
                  const Text(
                    ' ',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                ],
                Expanded(
                  child: Divider(
                    color: Colors.grey.shade300,
                    thickness: 1,
                  ),
                ),
                Text(' @${note.id} -',
                    style: const TextStyle(
                      fontWeight: FontWeight.w200,
                      fontSize: 12,
                    ))
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(4, 0, UserSession().isDesktop ? 4 : 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                note.isMarkdown
                    ? MarkdownBodyHere(
                        data: note.content + (note.isLong ? '...' : ''),
                      )
                    : SelectableText.rich(
                        TextSpan(
                          text: note.content + (note.isLong ? '...' : ''),
                          style: const TextStyle(
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.normal,
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black,
                          ),
                        ),
                      ),
                // fix #18 only show the tags row when necessary
                if (note.isLong || note.tags!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: note.tags!.map((tag) {
                          return TagWidget(
                            tag: tag,
                            onTap: () => onTagTap == null ? () {} : onTagTap!(note, tag),
                          );
                        }).toList(),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          Text(
                            note.isLong ? 'View more' : '',
                            style: const TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                          const Text(
                            '',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
