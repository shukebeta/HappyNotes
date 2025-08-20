import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../entities/note.dart';
import '../../utils/navigation_helper.dart';
import '../account/user_session.dart';
import '../note_detail/note_detail.dart';
import '../components/note_list/note_list_item.dart';
import '../components/note_list/note_list.dart';
import '../../providers/linked_notes_provider.dart';

class LinkedNotes extends StatefulWidget {
  final List<Note> linkedNotes; // Keep for compatibility but won't be used
  final Note parentNote;

  const LinkedNotes({
    Key? key,
    required this.linkedNotes,
    required this.parentNote,
  }) : super(key: key);

  @override
  LinkedNotesState createState() => LinkedNotesState();
}

class LinkedNotesState extends State<LinkedNotes> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Auto-load linked notes when widget initializes
    if (!_hasInitialized) {
      _hasInitialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = context.read<LinkedNotesProvider>();
        provider.loadLinkedNotes(widget.parentNote.id);
      });
    }
  }

  void onNoteSaved(Note updatedNote) {
    final provider = context.read<LinkedNotesProvider>();
    provider.updateLinkedNote(widget.parentNote.id, updatedNote);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LinkedNotesProvider>(
      builder: (context, provider, child) {
        final isLoading = provider.isLoading(widget.parentNote.id);
        final linkedNotes = provider.getLinkedNotes(widget.parentNote.id);
        final error = provider.getError(widget.parentNote.id);

        if (isLoading) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (error != null) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading linked notes: $error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          );
        }

        if (linkedNotes.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

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
                      callbacks: ListItemCallbacks<Note>(
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
                              enterEditing: widget.parentNote.userId == UserSession().id,
                              onNoteSaved: onNoteSaved, // Pass the optimized callback
                              fromDetailPage: false, // Not coming from detail page
                            ),
                          ),
                        ),
                      ),
                      onTagTap: (note, tag) => NavigationHelper.onTagTap(context, note, tag),
                      config: const ListItemConfig(
                        showDate: true,
                        showAuthor: true, // Show author for linked notes
                        showRestoreButton: false,
                        enableDismiss: false,
                      ),
                    ))
                .toList(),
          ]),
        );
      },
    );
  }
}
