import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_notes/apis/file_uploader_api.dart';
import 'package:happy_notes/apis/note_tag_api.dart';
import 'package:happy_notes/screens/components/controllers/html_to_markdown_converter.dart';
import 'package:happy_notes/screens/components/controllers/note_edit_controller.dart';
import 'package:happy_notes/screens/components/controllers/tag_controller.dart';
import 'package:happy_notes/services/clipboard_service.dart';
import 'package:happy_notes/services/image_service.dart';
import 'package:happy_notes/services/note_tag_service.dart';

class _FakeNoteTagApi extends NoteTagApi {
  @override
  Future<Response<dynamic>> getMyTagCloud() async =>
      Response(requestOptions: RequestOptions(), data: {'successful': true, 'data': []});
}

class _FakeImageService extends ImageService {
  _FakeImageService() : super(fileUploaderApi: FileUploaderApi());
}

TagController _makeTagController(NoteEditController noteEditController) {
  return TagController(
    noteTagService: NoteTagService(noteTagApi: _FakeNoteTagApi()),
    noteEditController: noteEditController,
  );
}

NoteEditController _makeNoteEditController() {
  return NoteEditController(
    imageService: _FakeImageService(),
    clipboardService: ClipboardService(),
    htmlToMarkdownConverter: HtmlToMarkdownConverter(),
  );
}

void main() {
  group('TagController.closeOverlay', () {
    late NoteEditController noteEditController;
    late TagController tagController;

    setUp(() {
      noteEditController = _makeNoteEditController();
      tagController = _makeTagController(noteEditController);
    });

    tearDown(() {
      tagController.dispose();
      noteEditController.dispose();
    });

    test('closeOverlay is a no-op when no overlay is open', () {
      expect(() => tagController.closeOverlay(), returnsNormally);
    });

    test('closeOverlay can be called multiple times without throwing', () {
      tagController.closeOverlay();
      tagController.closeOverlay();
      tagController.closeOverlay();
    });

    test('dispose throws AssertionError if called a second time', () {
      final ctrl = _makeTagController(noteEditController);
      ctrl.dispose();
      expect(() => ctrl.dispose(), throwsA(isA<AssertionError>()));
    });
  });
}
