import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'seq_logger.dart';

/// Clipboard payload for toolbar paste actions.
class ClipboardContent {
  final String? text;
  final String? html;
  final Uint8List? imageBytes;
  final String? unavailableMessage;

  const ClipboardContent({
    this.text,
    this.html,
    this.imageBytes,
    this.unavailableMessage,
  });
}

abstract class ClipboardPlatformAdapter {
  Future<ClipboardReaderHandle?> readClipboard();
}

abstract class ClipboardReaderHandle {
  Future<String?> readHtml();
  Future<String?> readText();
  Future<Uint8List?> readImage();
}

class ClipboardService {
  final ClipboardPlatformAdapter platformAdapter;

  ClipboardService({ClipboardPlatformAdapter? platformAdapter})
      : platformAdapter = platformAdapter ?? SuperClipboardPlatformAdapter();

  Future<ClipboardContent> readClipboardContent() async {
    final reader = await platformAdapter.readClipboard();
    if (reader == null) {
      return const ClipboardContent(
        unavailableMessage: kIsWeb
            ? 'Direct clipboard access is unavailable in this browser context. Try Ctrl+V, or use HTTPS/localhost.'
            : 'Clipboard access is not available on this platform.',
      );
    }

    final html = _normalizeString(await reader.readHtml());
    final text = _normalizeString(await reader.readText());
    final imageBytes = await reader.readImage();

    return ClipboardContent(
      text: text,
      html: html,
      imageBytes: imageBytes,
    );
  }

  String? _normalizeString(dynamic value) {
    if (value is! String) {
      return null;
    }

    final normalizedValue = value.trim();
    return normalizedValue.isEmpty ? null : normalizedValue;
  }
}

class SuperClipboardPlatformAdapter implements ClipboardPlatformAdapter {
  @override
  Future<ClipboardReaderHandle?> readClipboard() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      SeqLogger.info(
        'System clipboard API is not available on this platform or in this browser context',
      );
      return null;
    }

    try {
      return SuperClipboardReaderHandle(await clipboard.read());
    } catch (error, stackTrace) {
      SeqLogger.warning('Clipboard read failed', error, stackTrace);
      return null;
    }
  }
}

class SuperClipboardReaderHandle implements ClipboardReaderHandle {
  SuperClipboardReaderHandle(this.reader);

  static const List<FileFormat> _imageFormats = <FileFormat>[
    Formats.png,
    Formats.jpeg,
    Formats.gif,
    Formats.webp,
    Formats.tiff,
    Formats.bmp,
  ];

  final ClipboardReader reader;

  @override
  Future<String?> readHtml() async {
    try {
      if (!reader.canProvide(Formats.htmlText)) {
        return null;
      }
      return await reader.readValue(Formats.htmlText);
    } catch (error, stackTrace) {
      SeqLogger.fine(
        'Clipboard HTML access failed (expected fallback)',
        error,
        stackTrace,
      );
      return null;
    }
  }

  @override
  Future<String?> readText() async {
    try {
      if (!reader.canProvide(Formats.plainText)) {
        return null;
      }
      return await reader.readValue(Formats.plainText);
    } catch (error, stackTrace) {
      SeqLogger.fine(
        'Clipboard text access failed (expected fallback)',
        error,
        stackTrace,
      );
      return null;
    }
  }

  @override
  Future<Uint8List?> readImage() async {
    for (final FileFormat format in _imageFormats) {
      if (!reader.canProvide(format)) {
        continue;
      }

      try {
        final imageBytes = await _readFile(format);
        if (imageBytes != null && imageBytes.isNotEmpty) {
          return imageBytes;
        }
      } catch (error, stackTrace) {
        SeqLogger.fine(
          'Clipboard image access failed (expected fallback)',
          error,
          stackTrace,
        );
      }
    }

    return null;
  }

  Future<Uint8List?> _readFile(FileFormat format) async {
    final completer = Completer<Uint8List?>();
    final progress = reader.getFile(
      format,
      (DataReaderFile file) async {
        try {
          completer.complete(await file.readAll());
        } catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        }
      },
      onError: (Object error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );

    if (progress == null) {
      return null;
    }
    return completer.future;
  }
}
