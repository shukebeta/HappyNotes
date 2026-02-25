import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note_model.dart';
import 'shared_fab.dart';

/// Privacy toggle + Save FAB combination widget
class PrivacySaveFab extends StatelessWidget {
  final bool isSaving;
  final VoidCallback? onSave;
  final bool mini;
  final String? heroTag;

  const PrivacySaveFab({
    Key? key,
    required this.isSaving,
    this.onSave,
    this.mini = false,
    this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteModel>(
      builder: (context, noteModel, child) {
        return Opacity(
          opacity: 0.85,
          child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: IconButton(
                icon: Icon(
                  noteModel.isPrivate ? Icons.lock : Icons.lock_open,
                  color: noteModel.isPrivate ? Colors.blue : Colors.grey,
                ),
                onPressed: isSaving ? null : () {
                  noteModel.togglePrivate();
                },
                tooltip: noteModel.isPrivate ? 'Private' : 'Public',
              ),
            ),
            SharedFab(
              icon: isSaving ? Icons.hourglass_top : Icons.save,
              isPrivate: noteModel.isPrivate,
              busy: isSaving,
              mini: mini,
              onPressed: isSaving ? null : onSave,
              heroTag: heroTag,
            ),
          ],
          ),
        );
      },
    );
  }
}
