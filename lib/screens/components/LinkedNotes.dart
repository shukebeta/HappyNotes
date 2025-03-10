import 'package:flutter/material.dart';
import '../../entities/note.dart';
import '../../utils/navigation_helper.dart';
import '../account/user_session.dart';
import '../note_detail/note_detail.dart';
import 'note_list_item.dart';

class LinkedNotes extends StatelessWidget {
  final List<Note> linkedNotes;
  final Note parentNote;

  const LinkedNotes({
    Key? key,
    required this.linkedNotes,
    required this.parentNote,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (linkedNotes.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverList(
      delegate: SliverChildListDelegate([
        // "Linked Notes" header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Linked Notes",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        // Linked notes list
        ...linkedNotes
            .map((note) => NoteListItem(
                  note: note,
                  onTap: (note) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteDetail(note: note),
                    ),
                  ),
                  onDoubleTap: (note) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NoteDetail(
                        note: note,
                        enterEditing: parentNote.userId == UserSession().id,
                      ),
                    ),
                  ),
                  onTagTap: (note, tag) => NavigationHelper.onTagTap(context, note, tag),
                  showDate: true,
                ))
            .toList(),
      ]),
    );
  }
}
