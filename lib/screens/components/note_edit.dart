// NoteEdit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dependency_injection.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../services/image_service.dart';
import '../../services/note_tag_service.dart';
import '../../utils/happy_notes_prompts.dart';
import '../../utils/util.dart';
import 'controllers/note_edit_controller.dart';
import 'controllers/tag_controller.dart';

class NoteEdit extends StatefulWidget {
  final Note? note;

  const NoteEdit({
    Key? key,
    this.note,
  }) : super(key: key);

  @override
  NoteEditState createState() => NoteEditState();
}

class NoteEditState extends State<NoteEdit> {
  late String prompt;
  late NoteEditController noteEditController;
  late TagController tagController;

  @override
  void initState() {
    super.initState();
    final imageService = locator<ImageService>();
    final noteTagService = locator<NoteTagService>();
    noteEditController = NoteEditController(imageService: imageService);
    tagController = TagController(
        noteTagService: noteTagService, noteEditController: noteEditController);
    final noteModel = context.read<NoteModel>();
    prompt = HappyNotesPrompts.getRandom(noteModel.isPrivate);
    noteEditController.initialize(noteModel, widget.note, context);
  }

  @override
  void dispose() {
    noteEditController.dispose();
    tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteModel>(builder: (context, noteModel, child) {
      return Column(
        children: [
          Expanded(
            child: _buildEditor(noteModel),
          ),
          const SizedBox(height: 8.0),
          _buildActionButtons(context, noteModel),
        ],
      );
    });
  }

  Widget _buildEditor(NoteModel noteModel) {
    return Listener(
      onPointerDown: (event) {
        tagController.dispose(); // Close tag overlay if open
      },
      child: TextField(
        controller: noteEditController.textController,
        focusNode: noteModel.focusNode,
        keyboardType: TextInputType.multiline,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        decoration: InputDecoration(
          hintText: prompt,
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: noteModel.isPrivate ? Colors.blue : Colors.green,
              width: 2.0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color:
                  noteModel.isPrivate ? Colors.blueAccent : Colors.greenAccent,
              width: 2.0,
            ),
          ),
        ),
        onChanged: (text) {
          noteModel.content = text;
          tagController.handleTextChanged(text,
              noteEditController.textController.selection, noteModel, context);
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, NoteModel noteModel) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen =
        screenWidth < 400; // Adjust threshold as needed for iPhone SE size
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildActionButton(
              context,
              noteModel,
              icon: noteModel.isPrivate ? Icons.lock : Icons.lock_open,
              color: noteModel.isPrivate ? Colors.blue : Colors.grey,
              onTap: () => noteModel.togglePrivate(),
              isSmallScreen: isSmallScreen,
            ),
            _buildActionButton(
              context,
              noteModel,
              child: Text(
                "M↓",
                style: TextStyle(
                  fontSize: isSmallScreen ? 16.0 : 20.0,
                  color: noteModel.isMarkdown ? Colors.blue : Colors.grey,
                ),
              ),
              onTap: () => noteModel.toggleMarkdown(),
              isSmallScreen: isSmallScreen,
            ),
            if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS)
              _buildMarkdownActionButton(
                context: context,
                noteModel: noteModel,
                icon: Icons.add_photo_alternate,
                onPressed: () =>
                    noteEditController.pickAndUploadImage(context, noteModel),
                isLoading: noteModel.isUploading,
                isSmallScreen: isSmallScreen,
              ),
            if (Util.isPasteBoardSupported())
              _buildMarkdownActionButton(
                context: context,
                noteModel: noteModel,
                icon: Icons.paste,
                onPressed: () async => await noteEditController
                    .pasteFromClipboard(context, noteModel),
                isLoading: noteModel.isPasting,
                isSmallScreen: isSmallScreen,
              ),
            _buildActionButton(
              context,
              noteModel,
              icon: Icons.tag,
              onTap: () => tagController.showTagList(
                noteModel,
                noteEditController.textController.text,
                noteEditController.textController.selection.baseOffset,
                context,
              ),
              isSmallScreen: isSmallScreen,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    NoteModel noteModel, {
    required VoidCallback onTap,
    Widget? child,
    IconData? icon,
    Color? color,
    bool isSmallScreen = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
        child: child ??
            Icon(
              icon,
              color: color ?? Colors.black,
              size: isSmallScreen ? 20.0 : 24.0,
            ),
      ),
    );
  }

  Widget _buildMarkdownActionButton({
    required BuildContext context,
    required NoteModel noteModel,
    required IconData icon,
    required VoidCallback onPressed,
    required bool isLoading,
    bool isSmallScreen = false,
  }) {
    return Visibility(
      visible: noteModel.isMarkdown,
      maintainSize: true,
      maintainAnimation: true,
      maintainState: true,
      child: IconButton(
        onPressed: onPressed,
        icon: isLoading ? const CircularProgressIndicator() : Icon(icon),
        iconSize: isSmallScreen ? 20.0 : 24.0,
        padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
      ),
    );
  }
}
