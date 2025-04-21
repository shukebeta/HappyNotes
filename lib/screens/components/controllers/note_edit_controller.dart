import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/image_service.dart';
import '../../../models/note_model.dart';
import '../../../utils/util.dart';
import '../../../app_config.dart';
import '../../../entities/note.dart';
import '../image_warning_dialog.dart';

class NoteEditController {
  final ImageService imageService;
  TextEditingController textController = TextEditingController();

  NoteEditController({required this.imageService});

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
      if (!AppConfig.isIOSWeb) {
        noteModel.requestFocus();
      }
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

    // Note: Context is used after async operation. Since this is a controller and not a widget,
    // we assume the context passed is valid at the time of use. If issues arise, consider refactoring
    // to pass a dialog-showing callback or use a different pattern.
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
      await imageService.pasteFromClipboard(
        (text) {
          text = text.trim();
          if (text.isEmpty) return;

          final processedText =
              noteModel.isMarkdown && _urlPattern.hasMatch(text)
                  ? _processUrl(text)
                  : text;

          final cursorPosition = textController.selection.baseOffset;
          if (cursorPosition >= 0) {
            noteModel.content = noteModel.content.substring(0, cursorPosition) +
                processedText +
                noteModel.content.substring(cursorPosition);
            textController.selection = TextSelection.fromPosition(
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

  void dispose() {
    textController.dispose();
  }
}
