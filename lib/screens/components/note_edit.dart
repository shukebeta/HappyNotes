// NoteEdit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
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
        }
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
        _showTagList(noteModel, text, cursorPosition);
      });
    } else {
      _tagListTimer?.cancel();
      _tagListOverlay?.remove();
      _tagListOverlay = null;
    }
  }

  void _showTagList(
      NoteModel noteModel, String text, int cursorPosition) async {
    if (_tagListOverlay != null) return;

    List<String> tagsToShow;
    _tagListTimer?.cancel();
    final tagCloud = await noteTagService.getMyTagCloud();
    final sortedTags = tagCloud.keys.toList()
      ..sort((a, b) => tagCloud[b]!.compareTo(tagCloud[a]!));
    tagsToShow = sortedTags.take(5).toList();
    if (tagsToShow.isEmpty) return;

    // Delay creation of overlay slightly to get more accurate measurements
    Future.microtask(() {
      if (!mounted) return;

      // Calculate positions
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;

      final renderObject =
          noteModel.focusNode.context?.findRenderObject() as RenderBox?;
      if (renderObject == null) return;

      final offset = renderObject.localToGlobal(Offset.zero);

      // Get cursor position
      final linePosition = _getCursorLinePosition(cursorPosition);
      final horizontalPosition = _getCursorHorizontalPosition(cursorPosition);

      // Calculate dimensions
      const overlayHeight = 150.0;
      final overlayWidth = _calculateOverlayWidth(tagsToShow);

      // Base position calculation
      double top = offset.dy + linePosition;

      // Get keyboard height (estimate)
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      final effectiveScreenHeight = screenHeight - keyboardHeight;

      // Check if we're in the bottom half of the screen or near the bottom
      final bottomHalf = top > (effectiveScreenHeight / 2);
      final nearBottom = top + overlayHeight + 50 > effectiveScreenHeight;

      if (bottomHalf || nearBottom) {
        // Position well above cursor - ensure it's fully visible
        top = max(10, top - overlayHeight - 50);
      } else {
        // Position below cursor with offset
        top += 24.0; // standard line height
      }

      // Horizontal position - make sure it's visible
      double left = offset.dx + horizontalPosition;
      if (left + overlayWidth > screenWidth) {
        left = max(10, screenWidth - overlayWidth - 10);
      }
      left = max(10, left); // Ensure minimum margin

      // Create and insert overlay
      _tagListOverlay = OverlayEntry(
        builder: (context) => Positioned(
          top: top,
          left: left,
          width: overlayWidth,
          child: Material(
            elevation: 8.0, // Increased elevation for better visibility
            borderRadius: BorderRadius.circular(4.0),
            color: Colors.grey[200],
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: tagsToShow.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  title: Text(tagsToShow[index]),
                  onTap: () {
                    final tag = tagsToShow[index];
                    String newText;
                    int newCursorPosition;
                    if (cursorPosition > 0 && text[cursorPosition - 1] == '#') {
                      newText =
                          '${text.substring(0, cursorPosition)}$tag ${text.substring(cursorPosition)}';
                      newCursorPosition = cursorPosition + tag.length + 1;
                    } else {
                      newText =
                          '${text.substring(0, cursorPosition)}#$tag ${text.substring(cursorPosition)}';
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

      if (mounted) {
        Overlay.of(context).insert(_tagListOverlay!);
      }
    });
  }

  // Helper method to get cursor line position
  double _getCursorLinePosition(int cursorPosition) {
    final text = controller.text.substring(0, cursorPosition);
    final lines = text.split('\n');
    final cursorLine = lines.length - 1; // 0-based index
    const lineHeight = 24.0;
    return cursorLine * lineHeight;
  }

  // Helper method to get cursor horizontal position
  double _getCursorHorizontalPosition(int cursorPosition) {
    final text = controller.text.substring(0, cursorPosition);
    final lines = text.split('\n');
    final currentLine = lines.isNotEmpty ? lines.last : '';
    const charWidth = 9.0;
    return currentLine.length * charWidth;
  }

  double _calculateOverlayWidth(List<String> tags) {
    if (tags.isEmpty) return 300.0;
    final longestTag = tags.reduce((a, b) => a.length > b.length ? a : b);
    // Rough estimation: 10 pixels per character + padding
    return longestTag.length * 10.0 + 40.0;
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
        GestureDetector(
          onTap: () {
            _showTagList(noteModel, controller.text, controller.selection.baseOffset);
          },
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.all(12.0),
            child: Icon(
              Icons.tag,
              color: Colors.black,
              size: 24.0,
            ),
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

    if (!mounted) return false;

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

          final cursorPosition = controller.selection.baseOffset;
          if (cursorPosition >= 0) {
            noteModel.content = noteModel.content.substring(0, cursorPosition) +
                processedText +
                noteModel.content.substring(cursorPosition);
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: cursorPosition + processedText.length),
            );
          } else {
            noteModel.content += processedText;
          }
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
