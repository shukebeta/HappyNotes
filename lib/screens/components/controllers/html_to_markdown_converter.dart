import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// Converts common HTML fragments copied from webpages into readable Markdown.
class HtmlToMarkdownConverter {
  String? tryConvert(String? html) {
    final normalizedHtml = _normalize(html);
    if (normalizedHtml == null || !_looksLikeHtml(normalizedHtml)) {
      return null;
    }

    final fragment = html_parser.parseFragment(normalizedHtml);
    final hasElementNodes = fragment.nodes.any((Node node) => node is Element);
    if (!hasElementNodes) {
      return null;
    }

    final markdown = _cleanupBlock(_renderNodes(fragment.nodes));
    return markdown.isEmpty ? null : markdown;
  }

  String _renderNodes(List<Node> nodes, {int listDepth = 0}) {
    final buffer = StringBuffer();
    for (final Node node in nodes) {
      buffer.write(_renderNode(node, listDepth: listDepth));
    }
    return buffer.toString();
  }

  String _renderNode(Node node, {int listDepth = 0}) {
    if (node is Text) {
      return _normalizeInlineWhitespace(node.text);
    }

    if (node is! Element) {
      return '';
    }

    final tagName = node.localName?.toLowerCase();
    switch (tagName) {
      case 'br':
        return '\n';
      case 'p':
      case 'div':
      case 'section':
      case 'article':
      case 'header':
      case 'footer':
        return '${_cleanupInline(_renderNodes(node.nodes, listDepth: listDepth))}\n\n';
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        final level = int.tryParse(tagName!.substring(1)) ?? 1;
        return '${'#' * level} ${_cleanupInline(_renderNodes(node.nodes, listDepth: listDepth))}\n\n';
      case 'strong':
      case 'b':
        return '**${_cleanupInline(_renderNodes(node.nodes, listDepth: listDepth))}**';
      case 'em':
      case 'i':
        return '*${_cleanupInline(_renderNodes(node.nodes, listDepth: listDepth))}*';
      case 'del':
      case 's':
      case 'strike':
        return '~~${_cleanupInline(_renderNodes(node.nodes, listDepth: listDepth))}~~';
      case 'code':
        if (node.parent?.localName?.toLowerCase() == 'pre') {
          return node.text;
        }
        return '`${_cleanupInline(node.text)}`';
      case 'pre':
        final code = node.text.replaceAll('\r\n', '\n').trimRight();
        return code.isEmpty ? '' : '```\n$code\n```\n\n';
      case 'blockquote':
        return _renderBlockquote(node, listDepth: listDepth);
      case 'ul':
        return _renderList(node, ordered: false, listDepth: listDepth);
      case 'ol':
        return _renderList(node, ordered: true, listDepth: listDepth);
      case 'li':
        return _cleanupInline(_renderNodes(node.nodes, listDepth: listDepth));
      case 'a':
        return _renderLink(node, listDepth: listDepth);
      case 'img':
        return _renderImage(node);
      case 'hr':
        return '---\n\n';
      case 'span':
      case 'font':
      case 'small':
      case 'mark':
      case 'u':
      case 'body':
      case 'html':
        return _renderNodes(node.nodes, listDepth: listDepth);
      default:
        return _renderNodes(node.nodes, listDepth: listDepth);
    }
  }

  String _renderBlockquote(Element element, {required int listDepth}) {
    final content =
        _cleanupBlock(_renderNodes(element.nodes, listDepth: listDepth));
    if (content.isEmpty) {
      return '';
    }

    final quotedLines = content
        .split('\n')
        .map((String line) => line.isEmpty ? '>' : '> $line')
        .join('\n');
    return '$quotedLines\n\n';
  }

  String _renderList(Element element,
      {required bool ordered, required int listDepth}) {
    final items = element.children
        .where((Element child) => child.localName?.toLowerCase() == 'li')
        .toList();
    if (items.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    for (int index = 0; index < items.length; index++) {
      final prefix = ordered ? '${index + 1}. ' : '- ';
      buffer.write(_renderListItem(items[index], prefix, listDepth));
    }
    buffer.write('\n');
    return buffer.toString();
  }

  String _renderListItem(Element item, String prefix, int listDepth) {
    final indent = '  ' * listDepth;
    final contentParts = <String>[];
    final nestedLists = <String>[];

    for (final Node node in item.nodes) {
      if (node is Element) {
        final childTag = node.localName?.toLowerCase();
        if (childTag == 'ul' || childTag == 'ol') {
          nestedLists
              .add(_renderNode(node, listDepth: listDepth + 1).trimRight());
          continue;
        }
      }

      contentParts.add(_renderNode(node, listDepth: listDepth));
    }

    final content = _cleanupInline(contentParts.join());
    final buffer = StringBuffer();
    if (content.isNotEmpty) {
      buffer.writeln('$indent$prefix$content');
    }

    for (final String nestedList in nestedLists) {
      if (nestedList.isNotEmpty) {
        buffer.writeln(nestedList);
      }
    }

    return buffer.toString();
  }

  String _renderLink(Element element, {required int listDepth}) {
    final href = _normalize(element.attributes['href']);
    final text =
        _cleanupInline(_renderNodes(element.nodes, listDepth: listDepth));
    if (href == null) {
      return text;
    }

    final label = text.isEmpty ? href : text;
    return '[$label]($href)';
  }

  String _renderImage(Element element) {
    final src = _normalize(element.attributes['src']);
    if (src == null) {
      return '';
    }

    final alt = _cleanupInline(element.attributes['alt'] ?? '');
    return '![${alt.isEmpty ? 'image' : alt}]($src)';
  }

  bool _looksLikeHtml(String value) {
    return RegExp(r'<[a-zA-Z][^>]*>').hasMatch(value);
  }

  String _normalizeInlineWhitespace(String value) {
    if (value.trim().isEmpty) {
      return value.contains('\n') ? '' : ' ';
    }

    return value.replaceAll(RegExp(r'\s+'), ' ');
  }

  String _cleanupInline(String value) {
    return value
        .replaceAll(RegExp(r' *\n *'), '\n')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  String _cleanupBlock(String value) {
    return value
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  String? _normalize(String? value) {
    if (value == null) {
      return null;
    }

    final normalizedValue = value.trim();
    return normalizedValue.isEmpty ? null : normalizedValue;
  }
}
