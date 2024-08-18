import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class CodeElementBuilder extends MarkdownElementBuilder {
  bool _isMultipleLine(md.Element element) {
    return element.attributes['class'] != null || element.textContent.contains("\n");
  }

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final codeText = element.textContent;
    
    if (_isMultipleLine(element)) {
      return Container(
        margin: const EdgeInsets.fromLTRB(7, 20, 10, 0),
        width: MediaQueryData.fromView(WidgetsBinding.instance.window).size.width,
        child: Text(
          codeText,
          style: TextStyle(
            fontSize: preferredStyle!.fontSize,
            height: preferredStyle.height,
            color: preferredStyle.color,
            fontFamily: 'monospace',
          ),
        ),
      );
    } else {
      return Text(
        codeText,
        style: preferredStyle?.copyWith(
          backgroundColor: Colors.grey[200],
          fontFamily: 'monospace',
        ),
      );
    }
  }
}
