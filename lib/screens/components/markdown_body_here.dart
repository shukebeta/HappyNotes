import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'markdown/code_element_builder.dart';
import 'markdown/image_builder.dart';

class MarkdownBodyHere extends StatefulWidget {
  final String data;
  final bool isPrivate;

  const MarkdownBodyHere({
    super.key,
    required this.data,
    this.isPrivate = false,  // Default to non-private
  });

  @override
  State<StatefulWidget> createState() => MarkdownBodyHereState();
}

class MarkdownBodyHereState extends State<MarkdownBodyHere> {
  @override
  Widget build(BuildContext context) {
    // Define base color based on isPrivate flag
    final textColor = widget.isPrivate ? Colors.black54 : Colors.black87;

    final markdownBody = MarkdownBody(
      data: widget.data,
      builders: <String, MarkdownElementBuilder>{
        'code': CodeElementBuilder(),
        'img': ImageBuilder(context),
      },
      styleSheet: MarkdownStyleSheet(
        // Update all text elements to use the dynamic color
        h1: TextStyle(
          fontSize: 20,
          color: textColor,
        ),
        h2: TextStyle(color: textColor),
        h3: TextStyle(color: textColor),
        h4: TextStyle(color: textColor),
        h5: TextStyle(color: textColor),
        h6: TextStyle(color: textColor),
        p: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: textColor,
        ),
        code: TextStyle(
          fontSize: 16,
          height: 1.6,
          color: textColor,
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade200,
        ),
        // Add other text elements that need color control
        listBullet: TextStyle(color: textColor),
        strong: TextStyle(color: textColor),
        em: TextStyle(color: textColor),
      ),
      onTapLink: (text, url, title) {
        if (url != null) {
          launchUrlString(url);
        }
      },
    );

    // SelectionArea is now handled at the parent level (note list item)
    return markdownBody;
  }
}