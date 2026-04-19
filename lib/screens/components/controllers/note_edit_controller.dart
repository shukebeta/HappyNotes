import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/clipboard_service.dart';
import '../../../services/image_service.dart';
import '../../../models/note_model.dart';
import '../../../utils/util.dart';
import '../../../entities/note.dart';
import '../image_warning_dialog.dart';
import 'html_to_markdown_converter.dart';

class NoteEditController {
  final ImageService imageService;
  final ClipboardService clipboardService;
  final HtmlToMarkdownConverter htmlToMarkdownConverter;
  TextEditingController textController = TextEditingController();

  NoteEditController({
    required this.imageService,
    required this.clipboardService,
    required this.htmlToMarkdownConverter,
  });

  void initialize(NoteModel noteModel, Note? note, BuildContext context) {
    // Delay the update to avoid triggering a rebuild during the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (noteModel.initialContent.isNotEmpty && note == null) {
        noteModel.content = noteModel.initialContent;
      } else if (note != null) {
        noteModel.content = note.content;
      }

      // Set the initial text in the controller
      textController.text = noteModel.content;

      // Add listener to update controller.text when noteModel.content changes
      noteModel.addListener(() {
        if (noteModel.content != textController.text) {
          textController.text = noteModel.content;
        }
      });

      // Request focus
      noteModel.requestFocus();
    });
  }

  Future<bool> shouldShowWarning() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('hideImageWarning') ?? false);
  }

  Future<bool> showWarningDialog(BuildContext context) async {
    if (!await shouldShowWarning()) {
      return true;
    }

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const ImageWarningDialog(),
    );

    return result ?? false;
  }

  Future<void> pickAndUploadImage(
      BuildContext context, NoteModel noteModel) async {
    final scaffoldMessengerState = ScaffoldMessenger.of(context);

    // Show warning dialog first
    final proceed = await showWarningDialog(context);
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

  Future<void> pasteFromClipboard(
      BuildContext context, NoteModel noteModel) async {
    final scaffoldMessengerState = ScaffoldMessenger.of(context);
    try {
      noteModel.setPasting(true);
      final clipboardContent = await clipboardService.readClipboardContent();

      if (clipboardContent.imageBytes != null) {
        await imageService.uploadClipboardImage(
          clipboardContent.imageBytes!,
          (text) => insertTextAtCursor(noteModel, text),
          (error) => Util.showError(scaffoldMessengerState, error),
        );
        return;
      }

      final richText = buildRichPasteContent(
        clipboardContent: clipboardContent,
        isMarkdown: noteModel.isMarkdown,
      );

      if (richText != null) {
        insertTextAtCursor(noteModel, richText);
        return;
      }

      final plainText = buildTextPasteContent(
        clipboardContent: clipboardContent,
        isMarkdown: noteModel.isMarkdown,
      );
      if (plainText != null) {
        insertTextAtCursor(noteModel, plainText);
        return;
      }

      if (clipboardContent.unavailableMessage != null) {
        Util.showError(
          scaffoldMessengerState,
          clipboardContent.unavailableMessage!,
        );
        return;
      }

      Util.showError(
        scaffoldMessengerState,
        'No valid content found in clipboard.',
      );
    } finally {
      noteModel.setPasting(false);
    }
  }

  @visibleForTesting
  String? buildRichPasteContent({
    required ClipboardContent clipboardContent,
    required bool isMarkdown,
  }) {
    if (!isMarkdown) {
      return null;
    }

    return htmlToMarkdownConverter.tryConvert(clipboardContent.html);
  }

  @visibleForTesting
  String? buildTextPasteContent({
    required ClipboardContent clipboardContent,
    required bool isMarkdown,
  }) {
    final text = clipboardContent.text?.trim();
    if (text == null || text.isEmpty) {
      return null;
    }

    return isMarkdown && _urlPattern.hasMatch(text) ? _processUrl(text) : text;
  }

  @visibleForTesting
  void insertTextAtCursor(NoteModel noteModel, String text) {
    final cursorPosition = textController.selection.baseOffset;
    final insertionOffset =
        cursorPosition >= 0 ? cursorPosition : noteModel.content.length;
    final updatedContent = noteModel.content.substring(0, insertionOffset) +
        text +
        noteModel.content.substring(insertionOffset);

    textController.value = TextEditingValue(
      text: updatedContent,
      selection: TextSelection.collapsed(offset: insertionOffset + text.length),
    );
    noteModel.content = updatedContent;
  }

  String _processUrl(String url) {
    return _imageUrlPattern.hasMatch(url) ? '![image]($url)' : '<$url>';
  }

  void dispose() {
    textController.dispose();
  }
}
