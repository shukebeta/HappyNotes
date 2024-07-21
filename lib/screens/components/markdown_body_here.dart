import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'markdown/code_element_builder.dart';

class MarkdownBodyHere extends StatefulWidget {
  final String data;

  const MarkdownBodyHere({super.key, required this.data});

  @override
  State<StatefulWidget> createState() => MarkdownBodyHereState();
}

class MarkdownBodyHereState extends State<MarkdownBodyHere> {
  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: MarkdownBody(
        data: widget.data,
        builders: <String, MarkdownElementBuilder>{'code': CodeElementBuilder()},
        // Allow users to select text
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(fontSize: 24, color: Colors.blue),
          p: const TextStyle(
            fontSize: 16,
            height: 1.6,
          ),
          code: const TextStyle(fontSize: 16, height: 1.4, color: Colors.pink),
          codeblockDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
        ),
        onTapLink: (text, url, title) {
          if (url != null) {
            launchUrlString(url); // Assuming you have the url_launcher package added
          }
        },
        imageBuilder: (uri, title, alt) {
          return Image.network(uri.toString());
        },
      ),
    );
  }
}
