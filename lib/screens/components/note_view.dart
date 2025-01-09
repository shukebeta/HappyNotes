import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../utils/navigation_helper.dart';
import '../account/user_session.dart';
import '../note_detail/note_detail.dart';
import 'markdown_body_here.dart';
import 'note_list_item.dart'; // Import NoteListItem instead of NoteList

class NoteView extends StatelessWidget {
  final Note note;
  final List<Note>? linkedNotes;

  const NoteView({
    Key? key,
    required this.note,
    this.linkedNotes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteModel>(
      builder: (context, noteModel, child) {
        return CustomScrollView(
          slivers: [
            // Original note content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    note.isMarkdown
                        ? MarkdownBodyHere(data: note.content)
                        : Text(
                            note.formattedContent,
                            style: const TextStyle(fontSize: 16.0),
                          ),
                  ],
                ),
              ),
            ),

            // Linked notes section
            if (linkedNotes != null && linkedNotes!.isNotEmpty) ...[
              // "Linked Notes" header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Linked Notes",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),

              // Linked notes list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 1.0),
                    child: NoteListItem(
                      note: linkedNotes![index],
                      onTap: (note) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetail(note: note),
                        ),
                      ),
                      onDoubleTap: (note) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NoteDetail(note: note, enterEditing: note.userId == UserSession().id),
                        ),
                      ),
                      onTagTap: (note, tag) => NavigationHelper.onTagTap(context, note, tag),
                    ),
                  ),
                  childCount: linkedNotes!.length,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
