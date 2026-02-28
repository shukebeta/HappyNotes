import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happy_notes/screens/components/controllers/markdown_format_service.dart';

void main() {
  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController();
  });

  tearDown(() {
    controller.dispose();
  });

  group('MarkdownFormatService', () {
    group('wrapSelection', () {
      test('wraps selected text with bold syntax', () {
        controller.text = 'hello world';
        controller.selection = const TextSelection(baseOffset: 6, extentOffset: 11);
        String? result;

        MarkdownFormatService.wrapSelection(
          controller,
          prefix: '**',
          suffix: '**',
          onChanged: (text) => result = text,
        );

        expect(result, 'hello **world**');
        expect(controller.selection.baseOffset, 8);
        expect(controller.selection.extentOffset, 13);
      });

      test('inserts bold syntax at cursor when no selection', () {
        controller.text = 'hello world';
        controller.selection = const TextSelection.collapsed(offset: 5);
        String? result;

        MarkdownFormatService.wrapSelection(
          controller,
          prefix: '**',
          suffix: '**',
          onChanged: (text) => result = text,
        );

        expect(result, 'hello**** world');
        expect(controller.selection.baseOffset, 7); // cursor between **|**
      });

      test('unwraps already wrapped text', () {
        controller.text = 'hello **world**';
        controller.selection = const TextSelection(baseOffset: 8, extentOffset: 13);
        String? result;

        MarkdownFormatService.wrapSelection(
          controller,
          prefix: '**',
          suffix: '**',
          onChanged: (text) => result = text,
        );

        expect(result, 'hello world');
      });

      test('wraps with italic syntax', () {
        controller.text = 'hello world';
        controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
        String? result;

        MarkdownFormatService.wrapSelection(
          controller,
          prefix: '*',
          suffix: '*',
          onChanged: (text) => result = text,
        );

        expect(result, '*hello* world');
      });
    });

    group('toggleLinePrefix', () {
      test('adds bullet list prefix', () {
        controller.text = 'hello world';
        controller.selection = const TextSelection.collapsed(offset: 5);
        String? result;

        MarkdownFormatService.toggleLinePrefix(
          controller,
          prefix: '- ',
          onChanged: (text) => result = text,
        );

        expect(result, '- hello world');
      });

      test('removes existing bullet prefix', () {
        controller.text = '- hello world';
        controller.selection = const TextSelection.collapsed(offset: 5);
        String? result;

        MarkdownFormatService.toggleLinePrefix(
          controller,
          prefix: '- ',
          onChanged: (text) => result = text,
        );

        expect(result, 'hello world');
      });

      test('works on second line', () {
        controller.text = 'first line\nsecond line';
        controller.selection = const TextSelection.collapsed(offset: 15);
        String? result;

        MarkdownFormatService.toggleLinePrefix(
          controller,
          prefix: '> ',
          onChanged: (text) => result = text,
        );

        expect(result, 'first line\n> second line');
      });
    });

    group('cycleHeading', () {
      test('adds H1 to plain text', () {
        controller.text = 'hello';
        controller.selection = const TextSelection.collapsed(offset: 3);
        String? result;

        MarkdownFormatService.cycleHeading(
          controller,
          onChanged: (text) => result = text,
        );

        expect(result, '# hello');
      });

      test('cycles H1 to H2', () {
        controller.text = '# hello';
        controller.selection = const TextSelection.collapsed(offset: 5);
        String? result;

        MarkdownFormatService.cycleHeading(
          controller,
          onChanged: (text) => result = text,
        );

        expect(result, '## hello');
      });

      test('cycles H2 to H3', () {
        controller.text = '## hello';
        controller.selection = const TextSelection.collapsed(offset: 5);
        String? result;

        MarkdownFormatService.cycleHeading(
          controller,
          onChanged: (text) => result = text,
        );

        expect(result, '### hello');
      });

      test('removes H3 heading', () {
        controller.text = '### hello';
        controller.selection = const TextSelection.collapsed(offset: 6);
        String? result;

        MarkdownFormatService.cycleHeading(
          controller,
          onChanged: (text) => result = text,
        );

        expect(result, 'hello');
      });
    });

    group('insertLink', () {
      test('inserts link template when no selection', () {
        controller.text = 'hello ';
        controller.selection = const TextSelection.collapsed(offset: 6);
        String? result;

        MarkdownFormatService.insertLink(
          controller,
          onChanged: (text) => result = text,
        );

        expect(result, 'hello [link text](url)');
        // "link text" should be selected
        expect(controller.selection.baseOffset, 7);
        expect(controller.selection.extentOffset, 16);
      });

      test('wraps selected text as link text', () {
        controller.text = 'click here please';
        controller.selection = const TextSelection(baseOffset: 6, extentOffset: 10);
        String? result;

        MarkdownFormatService.insertLink(
          controller,
          onChanged: (text) => result = text,
        );

        expect(result, 'click [here](url) please');
        // "url" should be selected
        expect(controller.selection.baseOffset, 13);
        expect(controller.selection.extentOffset, 16);
      });
    });

    group('insertHorizontalRule', () {
      test('inserts horizontal rule at cursor', () {
        controller.text = 'above\nbelow';
        controller.selection = const TextSelection.collapsed(offset: 5);
        String? result;

        MarkdownFormatService.insertHorizontalRule(
          controller,
          onChanged: (text) => result = text,
        );

        expect(result, 'above\n\n---\n\n\nbelow');
      });
    });
  });
}
