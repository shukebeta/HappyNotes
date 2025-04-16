// NoteEdit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_config.dart';
import '../../dependency_injection.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../services/image_service.dart';
import '../../services/note_tag_service.dart';
import '../../utils/happy_notes_prompts.dart';
import '../../utils/util.dart';
import 'image_warning_dialog.dart';

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
  late NoteTagService noteTagService;
  Timer? _tagListTimer;
  OverlayEntry? _tagListOverlay;

  bool _isLongPress = false;

  @override
  void initState() {
    super.initState();
    imageService = locator<ImageService>();
    noteTagService = locator<NoteTagService>();
    controller = TextEditingController();
    final noteModel = context.read<NoteModel>();
    prompt = HappyNotesPrompts.getRandom(noteModel.isPrivate);

    // Delay the update to avoid triggering a rebuild during the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (noteModel.initialContent.isNotEmpty && widget.note == null) {
        noteModel.content = noteModel.initialContent;
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
    _tagListTimer?.cancel();
    _tagListOverlay?.remove();
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
    return Listener(
      onPointerDown: (event) {
        if (_tagListOverlay != null) {
          _tagListOverlay?.remove();
          _tagListOverlay = null;
        } else {
          _isLongPress = true;
          Timer(const Duration(milliseconds: 500), () {
            if (_isLongPress) {
              final cursorPosition = controller.selection.baseOffset;
              _handleLongPress(noteModel, controller.text, cursorPosition);
            }
          });
        }
      },
      onPointerUp: (event) {
        _isLongPress = false;
      },
      onPointerCancel: (event) {
        _isLongPress = false;
      },
      child: TextField(
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
              color:
                  noteModel.isPrivate ? Colors.blueAccent : Colors.greenAccent,
              width: 2.0,
            ),
          ),
        ),
        onChanged: (text) {
          noteModel.content = text;
          _handleTextChanged(text, controller.selection, noteModel);
        },
      ),
    );
  }

  void _handleTextChanged(
      String text, TextSelection selection, NoteModel noteModel) {
    final cursorPosition = selection.baseOffset;
    if (cursorPosition > 0 && text[cursorPosition - 1] == '#') {
      _tagListTimer?.cancel();
      _tagListTimer = Timer(const Duration(milliseconds: 200), () async {
        final tagCloud = await noteTagService.getMyTagCloud();
        final sortedTags = tagCloud.keys.toList()
          ..sort((a, b) => tagCloud[b]!.compareTo(tagCloud[a]!));
        final top5Tags = sortedTags.take(5).toList();
        _showTagList(top5Tags, noteModel, text, cursorPosition);
      });
    } else {
      _tagListTimer?.cancel();
      _tagListOverlay?.remove();
      _tagListOverlay = null;
    }
  }

  void _handleLongPress(
      NoteModel noteModel, String text, int cursorPosition) async {
    _tagListTimer?.cancel();
    final tagCloud = await noteTagService.getMyTagCloud();
    final sortedTags = tagCloud.keys.toList()
      ..sort((a, b) => tagCloud[b]!.compareTo(tagCloud[a]!));
    final top5Tags = sortedTags.take(5).toList();
    _showTagList(top5Tags, noteModel, text, cursorPosition);
  }

  void _showTagList(
      List<String> tags, NoteModel noteModel, String text, int cursorPosition) {
    if (_tagListOverlay != null) return;

    _tagListOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: noteModel.focusNode.offset.dy + 40,
        left: 0,
        width: MediaQuery.of(context).size.width,
        child: Material(
          elevation: 4.0,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tags.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(tags[index]),
                onTap: () {
                  final tag = tags[index];
                  String newText;
                  int newCursorPosition;
                  if (cursorPosition > 0 && text[cursorPosition - 1] == '#') {
                    newText = text.substring(0, cursorPosition) +
                        tag +
                        ' ' +
                        text.substring(cursorPosition);
                    newCursorPosition = cursorPosition + tag.length + 1;
                  } else {
                    newText = text.substring(0, cursorPosition) +
                        '#' +
                        tag +
                        ' ' +
                        text.substring(cursorPosition);
                    newCursorPosition = cursorPosition + tag.length + 2;
                  }
                  noteModel.content = newText;
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: newCursorPosition),
                  );
                  noteModel.requestFocus();
                  _tagListOverlay?.remove();
                  _tagListOverlay = null;
                },
              );
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_tagListOverlay!);
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
        if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS)
          Visibility(
            visible: noteModel.isMarkdown,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: IconButton(
              onPressed: noteModel.isMarkdown
                  ? () => _pickAndUploadImage(context, noteModel)
                  : null,
              icon: noteModel.isUploading
                  ? const CircularProgressIndicator()
                  : const Icon(Icons.add_photo_alternate),
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
            icon: noteModel.isPasting
                ? const CircularProgressIndicator()
                : const Icon(Icons.paste),
            iconSize: 24.0,
            padding: const EdgeInsets.all(12.0),
          ),
        ),
      ],
    );
  }

  Future<bool> _shouldShowWarning() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('hideImageWarning') ?? false);
  }

  Future<bool> _showWarningDialog() async {
    if (!await _shouldShowWarning()) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const ImageWarningDialog(),
    );

    return result ?? false;
  }

  Future<void> _pickAndUploadImage(
      BuildContext context, NoteModel noteModel) async {
    final scaffoldMessengerState = ScaffoldMessenger.of(context);

    // Show warning dialog first
    final proceed = await _showWarningDialog();
    if (!proceed) return;

    MultipartFile? imageFile = await imageService.pickImage();

    if (imageFile != null) {
      noteModel.setUploading(true);
      await imageService.uploadImage(
        imageFile,
        (text) {
          noteModel.setUploading(false);
          noteModel.content += noteModel.content.isEmpty ? text : '\n\n$text';
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

  Future<void> _pasteFromClipboard(
      BuildContext context, NoteModel noteModel) async {
    final scaffoldMessengerState = ScaffoldMessenger.of(context);
    try {
      noteModel.setPasting(true);
      await imageService.pasteFromClipboard(
        (text) {
          text = text.trim();
          if (text.isEmpty) return;

          final processedText =
              noteModel.isMarkdown && _urlPattern.hasMatch(text)
                  ? _processUrl(text)
                  : text;

          final separator =
              noteModel.content.isEmpty || noteModel.content.endsWith('\n')
                  ? ''
                  : '\n';
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
