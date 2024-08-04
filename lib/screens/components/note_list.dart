import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../entities/note.dart';
import 'note_list_item.dart';

class NoteList extends StatelessWidget {
  final List<Note> notes;
  final Function(Note) onTap;
  final Function(Note)? onDoubleTap;
  final Function(String tag)? onTagTap;
  final Future<void> Function()? onRefresh;
  final bool showDate;
  final bool showAuthor;
  final ScrollController _scrollController = ScrollController();

  NoteList({
    Key? key,
    required this.notes,
    required this.onTap,
    this.onDoubleTap,
    this.onTagTap,
    this.onRefresh,
    this.showDate = true,
    this.showAuthor = false,
  }) : super(key: key) {
    // Scroll to the top position when the widget is built or updated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Group notes by date
    final notesByDate = <String, List<Note>>{};
    for (var note in notes) {
      final dateKey = note.createdDate;
      notesByDate[dateKey] = notesByDate[dateKey] ?? [];
      notesByDate[dateKey]!.add(note);
    }

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        controller: _scrollController,
        itemCount: notesByDate.keys.length,
        itemBuilder: (context, index) {
          final dateKey = notesByDate.keys.elementAt(index);
          final dayNotes = notesByDate[dateKey]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              if (showDate)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      _formatDate(DateTime.parse(dateKey)),
                      style: const TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              // List of notes for that date with combined time and separator
              ...dayNotes.asMap().entries.map((entry) {
                final note = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
                  child: NoteListItem(
                    note: note,
                    onTap: () => onTap(note),
                    onDoubleTap: onDoubleTap != null ? () => onDoubleTap!(note) : null,
                    onTagTap: onTagTap,
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '- ${DateFormat('EEEE, MMM d, yyyy').format(date)} -';
  }
}
