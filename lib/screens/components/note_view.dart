import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../utils/navigation_helper.dart';
import 'markdown_body_here.dart';
import 'note_list.dart';

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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.isMarkdown ? 'Markdown Note' : 'Plain Text Note',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
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
            if (linkedNotes != null && linkedNotes!.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Linked Notes",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              SliverFillRemaining(
                child: NoteList(
                  showDate: false,
                  notes: linkedNotes!,
                  // Pass your list of notes here
                  onTap: (note) {
                    // Handle note tap
                  },
                  onDoubleTap: (note) {
                    // Handle note double tap
                  },
                  onTagTap: (note,tag) => NavigationHelper.onTagTap(context, note, tag),
                  onRefresh: () async {
                    // Handle refresh
                  },
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
