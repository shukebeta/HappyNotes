// NoteEdit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../app_config.dart';
import '../../dependency_injection.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../services/image_service.dart';
import '../../utils/happy_notes_prompts.dart';
import '../../utils/util.dart';

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
  late TextEditingController controller;
  late ImageService imageService;

  @override
  void initState() {
    super.initState();
    imageService = locator<ImageService>();
    controller = TextEditingController();
    final noteModel = context.read<NoteModel>();
    prompt = HappyNotesPrompts.getRandom(noteModel.isPrivate);

    // Delay the update to avoid triggering a rebuild during the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (noteModel.initialTag.isNotEmpty && widget.note == null) {
        noteModel.content = '#${noteModel.initialTag}\n';
        noteModel.initialTag = ''; // Reset after use
      } else if (widget.note != null) {
        noteModel.content = widget.note!.content;
      }

      // Set the initial text in the controller
      controller.text = noteModel.content;

      // Add listener to update controller.text when noteModel.content changes
      noteModel.addListener(() {
        if (noteModel.content != controller.text) {
          controller.text = noteModel.content;
        }
      });

      // Request focus and set prompt
      if (!AppConfig.isIOSWeb) {
        noteModel.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
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
    return TextField(
      controller: controller,
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
            color: noteModel.isPrivate ? Colors.blueAccent : Colors.greenAccent,
            width: 2.0,
          ),
        ),
      ),
      onChanged: (text) {
        noteModel.content = text;
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, NoteModel noteModel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            noteModel.togglePrivate();
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              noteModel.isPrivate ? Icons.lock : Icons.lock_open,
              color: noteModel.isPrivate ? Colors.blue : Colors.grey,
              size: 24.0,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            noteModel.toggleMarkdown();
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              "M↓",
              style: TextStyle(
                fontSize: 20.0,
                color: noteModel.isMarkdown ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        ),
        if (defaultTargetPlatform != TargetPlatform.macOS)
          Visibility(
            visible: noteModel.isMarkdown,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: IconButton(
              onPressed: noteModel.isMarkdown ? () => _pickAndUploadImage(context, noteModel) : null,
              icon: noteModel.isUploading ? const CircularProgressIndicator() : const Icon(Icons.add_photo_alternate),
              iconSize: 24.0,
              padding: const EdgeInsets.all(12.0),
            ),
          ),
        Visibility(
          visible: noteModel.isMarkdown && Util.isPasteBoardSupported(),
          maintainSize: true,
          maintainAnimation: true,
          maintainState: true,
          child: IconButton(
            onPressed: () async {
              await _pasteFromClipboard(context, noteModel);
            },
            icon: noteModel.isPasting ? const CircularProgressIndicator() : const Icon(Icons.paste),
            iconSize: 24.0,
            padding: const EdgeInsets.all(12.0),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, NoteModel noteModel) async {
    final scaffoldMessengerState = ScaffoldMessenger.of(context);
    MultipartFile? imageFile = await imageService.pickImage();

    if (imageFile != null) {
      noteModel.setUploading(true);
      await imageService.uploadImage(
        imageFile,
        (text) {
          noteModel.setUploading(false);
          noteModel.content += noteModel.content.isEmpty ? text : '\n$text';
        },
        (error) {
          noteModel.setUploading(false);
          Util.showError(scaffoldMessengerState, error);
        },
      );
    }
  }

  final _urlPattern = RegExp(r'^https?://[^\s<>]+$', caseSensitive: false);
  final _imageUrlPattern = RegExp(
    r'https?://[^\s<>]+\.(png|jpg|jpeg|gif|webp|bmp)(\?.*)?$',
    caseSensitive: false,
  );

  Future<void> _pasteFromClipboard(BuildContext context, NoteModel noteModel) async {
    final scaffoldMessengerState = ScaffoldMessenger.of(context);
    try {
      noteModel.setPasting(true);
      await imageService.pasteFromClipboard(
        (text) {
          text = text.trim();
          if (text.isEmpty) return;

          final processedText =
              noteModel.isMarkdown && _urlPattern.hasMatch(text) ? _processUrl(text) : text;

          final separator = noteModel.content.isEmpty || noteModel.content.endsWith('\n') ? '' : '\n';
          noteModel.content += separator + processedText;
        },
        (error) {
          Util.showError(scaffoldMessengerState, error);
        },
      );
    } finally {
      noteModel.setPasting(false);
    }
  }

  String _processUrl(String url) {
    return _imageUrlPattern.hasMatch(url) ? '![image]($url)' : '<$url>';
  }
}
