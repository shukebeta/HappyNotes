import 'package:flutter/material.dart';
import 'package:happy_notes/screens/account/user_session.dart';
import '../../entities/note.dart';
import 'markdown_body_here.dart';
import 'tag_widget.dart'; // Import your TagWidget

class NoteListItem extends StatelessWidget {
  final Note note;
  final bool showDate;
  final bool showAuthor;
  final bool showRestoreButton;
  final Function(Note)? onTap;
  final Function(Note)? onDoubleTap;
  final Function(Note note, String tag)? onTagTap;
  final Function(Note)? onRestoreTap;
  final Function(Note)? onDelete;
  final Future<bool> Function(DismissDirection)? confirmDismiss;

  NoteListItem({
    super.key,
    required this.note,
    this.onTap,
    this.onDoubleTap,
    this.onTagTap,
    this.onRestoreTap,
    this.onDelete,
    this.confirmDismiss,
    this.showDate = false,
    this.showAuthor = false,
    this.showRestoreButton = false,
  });

  @override
  Widget build(BuildContext context) {
    var author = (note.user == null || note.userId == UserSession().id || !showAuthor) ? '' : '${note.user!.username} ';
    var date = showDate ? '${note.createdDate} ' : '';

    Widget child = _buildChild(context);

    if (onDelete != null) {
      return Dismissible(
        key: Key(note.id.toString()),
        direction: DismissDirection.endToStart,
        // Swipe from right to left
        confirmDismiss: confirmDismiss,
        onDismissed: (direction) {
          onDelete!(note);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          color: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: child,
      );
    } else {
      return child;
    }
  }

  Widget _buildChild(BuildContext context) {
    var author = (note.user == null || note.userId == UserSession().id || !showAuthor) ? '' : '${note.user!.username} ';
    var date = showDate ? '${note.createdDate} ' : '';

    return GestureDetector(
        onTap: onTap != null ? () => onTap!(note) : null,
        onDoubleTap: onDoubleTap != null ? () => onDoubleTap!(note) : null,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                  child: Row(
                    children: [
                      Text(
                        '- $date${note.createdTime} $author - ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w300,
                          color: Colors.blue,
                          fontSize: 13,
                        ),
                      ),
                      ...[
                        if (note.isPrivate)
                          Icon(
                            Icons.lock,
                            color: Colors.grey.shade300,
                            size: 14,
                          ),
                        const Text(
                          ' ',
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ],
                      Expanded(
                        child: Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                      ),
                      Text(' ${note.id} ',
                          style: TextStyle(
                            fontWeight: FontWeight.w100,
                            color: Colors.blue.shade300,
                            fontSize: 13,
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
                              isPrivate: note.isPrivate,
                            )
                          : SelectableText.rich(
                              TextSpan(
                                text: note.content + (note.isLong ? '...' : ''),
                                style: TextStyle(
                                  fontStyle: FontStyle.normal,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 16,
                                  height: 1.6,
                                  color: note.isPrivate ? Colors.black54 : Colors.black87,
                                ),
                              ),
                            ),
                      // fix #18 only show the tags row when necessary
                      if (note.isLong || note.tags!.isNotEmpty)
                        Column(
                          children: [
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
                                    const Text(''),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (showRestoreButton && note.isDeleted)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () => onRestoreTap?.call(note),
                    child: const Text(
                      'Restore',
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                  ),
                ),
              ),
          ],
        ));
  }
}
