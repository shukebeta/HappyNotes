import 'package:flutter/material.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/utils/util.dart';

import '../entities/note.dart';
import '../screens/components/tag_cloud.dart';
import '../screens/tag_notes/tag_notes.dart';

class NavigationHelper {
  static Future<void> onTagTap(BuildContext context, Note note, String tag) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => tag.startsWith('@')
            ? NoteDetail(noteId: int.parse(tag.substring(1)))
            : TagNotes(tag: tag, myNotesOnly: true),
      ),
    );
  }

  static Future<void> showTagInputDialog(BuildContext context) async {
    final navigator = Navigator.of(context);
    var newTag = await Util.showInputDialog(context, 'Type a tag', 'such as laugh');
    if (newTag == null) return;
    newTag = newTag.isEmpty ? 'laugh' : newTag;
    newTag = _cleanTag(newTag);
    if (newTag.isNotEmpty) {
      navigator.push(
        MaterialPageRoute(
          builder: (context) => newTag!.startsWith('@')
              ? NoteDetail(noteId: int.parse(newTag.substring(1)))
              : TagNotes(tag: newTag, myNotesOnly: true),
        ),
      );
    }
  }

  static void showTagDiagram(BuildContext context, Map<String, int> tagData,
      {bool replacePage = true, bool myNotesOnly = true}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tag Cloud'),
          content: SingleChildScrollView(
            child: TagCloud(
              tagData: tagData,
              onTagTap: (tag) {
                _navigateToTagNotes(context, tag, replacePage: replacePage, myNotesOnly: myNotesOnly);
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static void _navigateToTagNotes(BuildContext context, String tag,
      {bool replacePage = true, bool myNotesOnly = true}) {
    if (replacePage) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TagNotes(tag: tag, myNotesOnly: myNotesOnly),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TagNotes(tag: tag, myNotesOnly: myNotesOnly),
        ),
      );
    }
  }

  static String _cleanTag(String tag) {
    if (int.tryParse(tag) != null) {
      tag = '@$tag';
    } else {
      if (tag.startsWith('#')) {
        tag = tag.replaceAll('#', '');
      }
    }
    return tag.trim();
  }
}
