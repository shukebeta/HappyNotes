import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../entities/note.dart';
import '../memories/memories_on_day.dart';
import 'note_list_item.dart';

class NoteList extends StatelessWidget {
  final List<Note> notes;
  final Function(Note) onTap;
  final Function(Note)? onDoubleTap;
  final Function(Note note, String tag)? onTagTap;
  final Future<void> Function()? onRefresh;
  final bool showDate;
  final bool showAuthor;
  final bool showRestoreButton;
  final Function(Note)? onRestoreTap;
  final Function(Note)? onDelete;
  final Future<bool> Function(DismissDirection)? confirmDismiss;
  final ScrollController _scrollController = ScrollController();

  NoteList({
    Key? key,
    required this.notes,
    required this.onTap,
    this.onDoubleTap,
    this.onTagTap,
    this.onRefresh,
    this.onRestoreTap,
    this.onDelete,
    this.confirmDismiss = null,
    this.showDate = false,
    this.showAuthor = false,
    this.showRestoreButton = false,
  }) : super(key: key);

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
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Align(
                    alignment: Alignment.center,
                    child: InkWell(
                      onTap: onTagTap != null ? () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (context) => MemoriesOnDay(date: DateTime.parse(dateKey)),
                        ),
                      ) : null,
                      child: Text(
                        _formatDate(DateTime.parse(dateKey)),
                        style: const TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 16,
                        ),
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
                    onTap: onTap,
                    onDoubleTap: onDoubleTap,
                    onTagTap: onTagTap,
                    onRestoreTap: onRestoreTap,
                    onDelete: onDelete,
                    confirmDismiss: confirmDismiss,
                    showDate: showDate,
                    showAuthor: showAuthor,
                    showRestoreButton: showRestoreButton,
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
