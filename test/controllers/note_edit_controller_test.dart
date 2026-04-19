import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_notes/apis/file_uploader_api.dart';
import 'package:happy_notes/models/note_model.dart';
import 'package:happy_notes/screens/components/controllers/html_to_markdown_converter.dart';
import 'package:happy_notes/screens/components/controllers/note_edit_controller.dart';
import 'package:happy_notes/services/clipboard_service.dart';
import 'package:happy_notes/services/image_service.dart';

class FakeClipboardService extends ClipboardService {
  ClipboardContent nextContent = const ClipboardContent();

  @override
  Future<ClipboardContent> readClipboardContent() async {
    return nextContent;
  }
}

class FakeImageService extends ImageService {
  FakeImageService() : super(fileUploaderApi: FileUploaderApi());

  bool pasteImageCalled = false;
  Future<void> Function(Uint8List imageBytes, Function(String) onSuccess,
      Function(String) onError)? pasteImageHandler;

  @override
  Future<void> uploadClipboardImage(Uint8List imageBytes,
      Function(String) onSuccess, Function(String) onError) async {
    pasteImageCalled = true;
    if (pasteImageHandler != null) {
      await pasteImageHandler!(imageBytes, onSuccess, onError);
    }
  }
}

void main() {
  group('NoteEditController', () {
    late FakeClipboardService clipboardService;
    late FakeImageService imageService;
    late NoteEditController controller;

    setUp(() {
      clipboardService = FakeClipboardService();
      imageService = FakeImageService();
      controller = NoteEditController(
        imageService: imageService,
        clipboardService: clipboardService,
        htmlToMarkdownConverter: HtmlToMarkdownConverter(),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('prefers html conversion in markdown mode', () {
      final processedText = controller.buildRichPasteContent(
        clipboardContent: const ClipboardContent(
          text: 'Clip Title Hello world',
          html: '<h2>Clip Title</h2><p>Hello <strong>world</strong></p>',
        ),
        isMarkdown: true,
      );

      expect(processedText, '## Clip Title\n\nHello **world**');
    });

    test('keeps plain text in non-markdown mode', () {
      final processedText = controller.buildTextPasteContent(
        clipboardContent: const ClipboardContent(
          text: 'Clip Title Hello world',
          html: '<h2>Clip Title</h2><p>Hello <strong>world</strong></p>',
        ),
        isMarkdown: false,
      );

      expect(processedText, 'Clip Title Hello world');
    });

    test('wraps pasted image urls in markdown mode', () {
      final processedText = controller.buildTextPasteContent(
        clipboardContent: const ClipboardContent(
          text: 'https://example.com/image.png',
        ),
        isMarkdown: true,
      );

      expect(processedText, '![image](https://example.com/image.png)');
    });

    test('inserts text at the current cursor position', () {
      final noteModel = NoteModel(content: 'Hello world');
      controller.textController.value = const TextEditingValue(
        text: 'Hello world',
        selection: TextSelection.collapsed(offset: 6),
      );

      controller.insertTextAtCursor(noteModel, '**new** ');

      expect(noteModel.content, 'Hello **new** world');
      expect(controller.textController.text, 'Hello **new** world');
      expect(controller.textController.selection.baseOffset, 14);
    });

    testWidgets('pastes converted html through toolbar flow',
        (WidgetTester tester) async {
      late BuildContext context;
      final noteModel = NoteModel(isMarkdown: true, content: 'Start ');
      controller.textController.value = const TextEditingValue(
        text: 'Start ',
        selection: TextSelection.collapsed(offset: 6),
      );
      clipboardService.nextContent = const ClipboardContent(
        text: 'Start clip',
        html: '<p>Hello <strong>clip</strong></p>',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext buildContext) {
              context = buildContext;
              return const SizedBox();
            },
          ),
        ),
      );

      await controller.pasteFromClipboard(context, noteModel);

      expect(noteModel.content, 'Start Hello **clip**');
      expect(imageService.pasteImageCalled, isFalse);
      expect(noteModel.isPasting, isFalse);
    });

    testWidgets('prefers clipboard image over plain text fallback',
        (WidgetTester tester) async {
      late BuildContext context;
      final noteModel = NoteModel(isMarkdown: true, content: 'Start ');
      controller.textController.value = const TextEditingValue(
        text: 'Start ',
        selection: TextSelection.collapsed(offset: 6),
      );
      clipboardService.nextContent = ClipboardContent(
        text: 'Descriptive clipboard text',
        imageBytes: Uint8List.fromList(<int>[1, 2, 3]),
      );
      imageService.pasteImageHandler = (imageBytes, onSuccess, onError) async {
        onSuccess('![image](https://example.com/from-clipboard.png)');
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext buildContext) {
              context = buildContext;
              return const SizedBox();
            },
          ),
        ),
      );

      await controller.pasteFromClipboard(context, noteModel);

      expect(noteModel.content,
          'Start ![image](https://example.com/from-clipboard.png)');
      expect(imageService.pasteImageCalled, isTrue);
      expect(noteModel.isPasting, isFalse);
    });

    testWidgets(
        'falls back to clipboard image paste when no text content exists',
        (WidgetTester tester) async {
      late BuildContext context;
      final noteModel = NoteModel(isMarkdown: true, content: 'Start ');
      controller.textController.value = const TextEditingValue(
        text: 'Start ',
        selection: TextSelection.collapsed(offset: 6),
      );
      clipboardService.nextContent = const ClipboardContent();
      imageService.pasteImageHandler = (imageBytes, onSuccess, onError) async {
        expect(imageBytes, isNotEmpty);
        onSuccess('![image](https://example.com/from-clipboard.png)');
      };
      clipboardService.nextContent =
          ClipboardContent(imageBytes: Uint8List.fromList(<int>[1, 2, 3]));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext buildContext) {
              context = buildContext;
              return const SizedBox();
            },
          ),
        ),
      );

      await controller.pasteFromClipboard(context, noteModel);

      expect(noteModel.content,
          'Start ![image](https://example.com/from-clipboard.png)');
      expect(imageService.pasteImageCalled, isTrue);
      expect(noteModel.isPasting, isFalse);
    });

    testWidgets('shows error when clipboard has no supported content',
        (WidgetTester tester) async {
      late BuildContext context;
      final noteModel = NoteModel(isMarkdown: true, content: 'Start ');
      controller.textController.value = const TextEditingValue(
        text: 'Start ',
        selection: TextSelection.collapsed(offset: 6),
      );
      clipboardService.nextContent = const ClipboardContent();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext buildContext) {
                context = buildContext;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await controller.pasteFromClipboard(context, noteModel);
      await tester.pump();

      expect(imageService.pasteImageCalled, isFalse);
      expect(find.text('No valid content found in clipboard.'), findsOneWidget);
      expect(noteModel.isPasting, isFalse);
    });

    testWidgets(
        'shows clearer message when direct clipboard access is unavailable',
        (WidgetTester tester) async {
      late BuildContext context;
      final noteModel = NoteModel(isMarkdown: true, content: 'Start ');
      controller.textController.value = const TextEditingValue(
        text: 'Start ',
        selection: TextSelection.collapsed(offset: 6),
      );
      clipboardService.nextContent = const ClipboardContent(
        unavailableMessage:
            'Direct clipboard access is unavailable in this browser context. Try Ctrl+V, or use HTTPS/localhost.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext buildContext) {
                context = buildContext;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await controller.pasteFromClipboard(context, noteModel);
      await tester.pump();

      expect(imageService.pasteImageCalled, isFalse);
      expect(
        find.textContaining('Try Ctrl+V, or use HTTPS/localhost.'),
        findsOneWidget,
      );
      expect(noteModel.isPasting, isFalse);
    });
  });
}
