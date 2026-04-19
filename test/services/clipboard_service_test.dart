import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:happy_notes/services/clipboard_service.dart';

class FakeClipboardPlatformAdapter implements ClipboardPlatformAdapter {
  ClipboardReaderHandle? nextReader;

  @override
  Future<ClipboardReaderHandle?> readClipboard() async {
    return nextReader;
  }
}

class FakeClipboardReaderHandle implements ClipboardReaderHandle {
  FakeClipboardReaderHandle({
    this.html,
    this.text,
    this.imageBytes,
  });

  final String? html;
  final String? text;
  final Uint8List? imageBytes;

  @override
  Future<String?> readHtml() async => html;

  @override
  Future<Uint8List?> readImage() async => imageBytes;

  @override
  Future<String?> readText() async => text;
}

void main() {
  group('ClipboardService', () {
    late FakeClipboardPlatformAdapter adapter;
    late ClipboardService service;

    setUp(() {
      adapter = FakeClipboardPlatformAdapter();
      service = ClipboardService(platformAdapter: adapter);
    });

    test('returns normalized html and text values', () async {
      adapter.nextReader = FakeClipboardReaderHandle(
        html: '  <p>Hello</p>  ',
        text: '  Hello  ',
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      final content = await service.readClipboardContent();

      expect(content.html, '<p>Hello</p>');
      expect(content.text, 'Hello');
      expect(content.imageBytes, Uint8List.fromList(<int>[1, 2, 3]));
    });

    test('loads image bytes when text and html are unavailable', () async {
      final bytes = Uint8List.fromList(<int>[1, 2, 3]);
      adapter.nextReader = FakeClipboardReaderHandle(imageBytes: bytes);

      final content = await service.readClipboardContent();

      expect(content.text, isNull);
      expect(content.html, isNull);
      expect(content.imageBytes, bytes);
    });

    test('returns unavailable message when clipboard reader is missing',
        () async {
      adapter.nextReader = null;

      final content = await service.readClipboardContent();

      expect(content.text, isNull);
      expect(content.html, isNull);
      expect(content.imageBytes, isNull);
      expect(content.unavailableMessage, isNotNull);
    });

    test('still loads image bytes when html content exists', () async {
      adapter.nextReader = FakeClipboardReaderHandle(
        html: '<p>Hello</p>',
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      );

      final content = await service.readClipboardContent();

      expect(content.html, '<p>Hello</p>');
      expect(content.imageBytes, Uint8List.fromList(<int>[1, 2, 3]));
    });
  });
}
