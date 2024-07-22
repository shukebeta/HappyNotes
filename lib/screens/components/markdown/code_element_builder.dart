import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class CodeElementBuilder extends MarkdownElementBuilder {
  bool _isMutipleLine(md.Element element) {
    return element.attributes['class'] != null || element.textContent.contains("\n");
  }

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (_isMutipleLine(element)) {
      return Container(
        margin: const EdgeInsets.fromLTRB(7, 20, 10, 0),
        width: MediaQueryData.fromView(WidgetsBinding.instance.window).size.width,
        child: Text(
          element.textContent,
          style: TextStyle(fontSize: preferredStyle!.fontSize, height: preferredStyle.height, color: preferredStyle.color),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(2),
        child: Text(
          element.textContent,
          style: TextStyle(fontSize: preferredStyle!.fontSize, height: preferredStyle.height, color: preferredStyle.color),
        ),
      );
    }
  }
}
