// NoteEdit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../dependency_injection.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../services/image_service.dart';
import '../../services/note_tag_service.dart';
import '../../utils/happy_notes_prompts.dart';
import 'controllers/note_edit_controller.dart';
import 'controllers/tag_controller.dart';
import 'markdown_toolbar.dart';

class NoteEdit extends StatefulWidget {
  final Note? note;
  final VoidCallback? onSubmit;
  final bool isSaving;

  const NoteEdit({
    Key? key,
    this.note,
    this.onSubmit,
    this.isSaving = false,
  }) : super(key: key);

  @override
  NoteEditState createState() => NoteEditState();
}

class NoteEditState extends State<NoteEdit> {
  late String prompt;
  late NoteEditController noteEditController;
  late TagController tagController;
  final UndoHistoryController _undoController = UndoHistoryController();

  @override
  void initState() {
    super.initState();
    final imageService = locator<ImageService>();
    final noteTagService = locator<NoteTagService>();
    noteEditController = NoteEditController(imageService: imageService);
    tagController = TagController(noteTagService: noteTagService, noteEditController: noteEditController);
    final noteModel = context.read<NoteModel>();
    prompt = HappyNotesPrompts.getRandom(noteModel.isPrivate);
    noteEditController.initialize(noteModel, widget.note, context);
  }

  @override
  void dispose() {
    _undoController.dispose();
    noteEditController.dispose();
    tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteModel>(builder: (context, noteModel, child) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 400;
      final isMobile = defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;

      final toolbar = MarkdownToolbar(
        textController: noteEditController.textController,
        undoController: _undoController,
        focusNode: noteModel.focusNode,
        onChanged: (text) {
          noteModel.content = text;
        },
        isMarkdown: noteModel.isMarkdown,
        onToggleMarkdown: () => noteModel.toggleMarkdown(),
        onTagPressed: () => tagController.showTagList(
          noteModel,
          noteEditController.textController.text,
          noteEditController.textController.selection.baseOffset,
          context,
        ),
        onImageUpload: () => noteEditController.pickAndUploadImage(context, noteModel),
        onPaste: () async => await noteEditController.pasteFromClipboard(context, noteModel),
        isUploading: noteModel.isUploading,
        isPasting: noteModel.isPasting,
        isSmallScreen: isSmallScreen,
      );

      final editor = Expanded(
        child: Stack(
          children: [
            _buildEditor(noteModel),
            Positioned(
              right: 8.0,
              bottom: 8.0,
              child: _buildFloatingButtons(noteModel),
            ),
          ],
        ),
      );

      return Column(
        children: isMobile
            ? [editor, toolbar]
            : [toolbar, editor],
      );
    });
  }

  Widget _buildFloatingButtons(NoteModel noteModel) {
    return Opacity(
      opacity: 0.7,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Privacy toggle
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isSaving ? null : () => noteModel.togglePrivate(),
              borderRadius: BorderRadius.circular(20.0),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  noteModel.isPrivate ? Icons.lock : Icons.lock_open,
                  color: noteModel.isPrivate ? Colors.blue : Colors.grey,
                  size: 20.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          // Save button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (widget.isSaving || noteModel.isUploading) ? null : widget.onSubmit,
              borderRadius: BorderRadius.circular(20.0),
              child: Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: (widget.isSaving || noteModel.isUploading)
                    ? const SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : Icon(
                        Icons.save,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20.0,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(NoteModel noteModel) {
    const baseBorderColor = Colors.grey;
    final focusedBorderColor = noteModel.isPrivate ? Colors.blueAccent : Colors.orangeAccent;
    final backgroundColor = noteModel.isPrivate ? Colors.blue.shade50 : Colors.white;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (widget.onSubmit != null) {
            widget.onSubmit!();
          }
        },
      },
      child: Listener(
        onPointerDown: (event) {
          tagController.dispose(); // Close tag overlay if open
        },
        child: AnimatedBuilder(
          animation: noteModel.focusNode,
          builder: (context, child) {
            final hasFocus = noteModel.focusNode.hasFocus;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(
                  color: hasFocus ? focusedBorderColor : baseBorderColor,
                  width: 2.0,
                ),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: TextField(
                controller: noteEditController.textController,
                undoController: _undoController,
                focusNode: noteModel.focusNode,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                expands: true,
                enableInteractiveSelection: true,
                stylusHandwritingEnabled: true,
                style: const TextStyle(color: Colors.black, height: 1.5),
                decoration: InputDecoration(
                  hintText: prompt,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14.0),
                ),
                onChanged: (text) {
                  noteModel.content = text;
                  tagController.handleTextChanged(text, noteEditController.textController.selection, noteModel, context);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
