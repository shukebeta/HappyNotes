import 'package:flutter/material.dart';
import 'package:happy_notes/screens/note_detail/note_detail.dart';
import 'package:happy_notes/utils/util.dart';

import '../entities/note.dart';
import '../screens/components/tag_cloud.dart';
import '../screens/memories/memories_on_day.dart';
import '../screens/tag_notes/tag_notes.dart';
import '../screens/search/search_results_page.dart';

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

  static Future<void> showTagInputDialog(BuildContext context, {bool replacePage = false}) async {
    final navigator = Navigator.of(context);
    // Use the new dialog function
    final result = await Util.showKeywordOrTagDialog(
      context,
      'Find Notes', // Updated title
      'Enter keyword, tag, date, or ID', // Updated hint
    );

    // Handle null or cancel
    if (result == null || result['action'] == 'cancel') {
      return;
    }

    final action = result['action'];
    final inputText = result['text'] ?? '';

    if (inputText.isEmpty) return; // Don't proceed if text is empty

    if (action == 'go') {
      // Simplified logic: try date first, then search
      final dateString = _normalizeDateString(inputText);
      if (dateString != null) {
        try {
          final date = DateTime.parse(dateString);
          if (replacePage) {
            navigator.pushReplacement(
              MaterialPageRoute(builder: (context) => MemoriesOnDay(date: date)),
            );
          } else {
            navigator.push(
              MaterialPageRoute(builder: (context) => MemoriesOnDay(date: date)),
            );
          }
          return;
        } catch (e) {
          // If date parsing fails, continue to search
        }
      }
      
      // Not a date - perform search
      if (replacePage) {
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => SearchResultsPage(query: inputText),
          ),
        );
      } else {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => SearchResultsPage(query: inputText),
          ),
        );
      }
    }
  }

  static String? _normalizeDateString(String input) {
    // Match yyyy-MMM-dd or yyyy-M-d format
    final monthNames = {
      'jan': '01',
      'feb': '02',
      'mar': '03',
      'apr': '04',
      'may': '05',
      'jun': '06',
      'jul': '07',
      'aug': '08',
      'sep': '09',
      'oct': '10',
      'nov': '11',
      'dec': '12'
    };

    // Try yyyy-MMM-dd format
    final monthNamePattern =
        RegExp(r'^(\d{4})-(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)-(\d{2})$', caseSensitive: false);
    final monthMatch = monthNamePattern.firstMatch(input);
    if (monthMatch != null) {
      final year = monthMatch.group(1);
      final month = monthNames[monthMatch.group(2)?.toLowerCase()];
      final day = monthMatch.group(3);
      return '$year-$month-$day';
    }

    // Try yyyy-M-d format
    final numericPattern = RegExp(r'^(\d{4})-(0?[1-9]|1[0-2])-(0?[1-9]|[12]\d|3[01])$');
    final numericMatch = numericPattern.firstMatch(input);
    if (numericMatch != null) {
      final year = numericMatch.group(1);
      final month = numericMatch.group(2)!.padLeft(2, '0');
      final day = numericMatch.group(3)!.padLeft(2, '0');
      return '$year-$month-$day';
    }

    return null;
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



  static Future<void> showJumpToNoteDialog(BuildContext context) async {
    final navigator = Navigator.of(context);
    final result = await Util.showKeywordOrTagDialog(
      context,
      'Jump to Note', // Focused title
      'Enter note ID', // ID-specific hint
    );

    // Handle null or cancel
    if (result == null || result['action'] == 'cancel') {
      return;
    }

    final action = result['action'];
    final inputText = result['text'] ?? '';

    if (inputText.isEmpty) return;

    if (action == 'go') {
      // Try to parse as note ID
      final noteId = int.tryParse(inputText);
      if (noteId != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (context) => NoteDetail(noteId: noteId),
          ),
        );
      }
    }
  }
  static bool isValidTagFormat(String text) {
    // Only require no spaces and non-empty after trim
    return !text.contains(' ') && text.trim().isNotEmpty;
  }
}
