import 'package:flutter_test/flutter_test.dart';
import 'package:happy_notes/screens/components/controllers/html_to_markdown_converter.dart';

void main() {
  group('HtmlToMarkdownConverter', () {
    late HtmlToMarkdownConverter converter;

    setUp(() {
      converter = HtmlToMarkdownConverter();
    });

    test('returns null for non-html text', () {
      expect(converter.tryConvert('just plain text'), isNull);
    });

    test('converts headings emphasis and links', () {
      const html = '''
        <h2>Clip Title</h2>
        <p>Hello <strong>world</strong> and <em>friends</em>.</p>
        <p><a href="https://example.com">Read more</a></p>
      ''';

      expect(
        converter.tryConvert(html),
        '## Clip Title\n\nHello **world** and *friends*.\n\n[Read more](https://example.com)',
      );
    });

    test('converts lists blockquotes code blocks and images', () {
      const html = '''
        <ul><li>One</li><li>Two</li></ul>
        <blockquote><p>Quoted line</p></blockquote>
        <pre><code>final a = 1;\nprint(a);</code></pre>
        <img src="https://example.com/image.png" alt="clip" />
      ''';

      expect(
        converter.tryConvert(html),
        '- One\n- Two\n\n> Quoted line\n\n```\nfinal a = 1;\nprint(a);\n```\n\n![clip](https://example.com/image.png)',
      );
    });
  });
}
