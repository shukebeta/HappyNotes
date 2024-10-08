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
        // Allow users to select text
        builders: <String, MarkdownElementBuilder>{'code': CodeElementBuilder()},
        styleSheet: MarkdownStyleSheet(
          h1: const TextStyle(fontSize: 20),
          p: const TextStyle(
            fontSize: 16,
            height: 1.6,
          ),
          code: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87, fontFamily: 'monospace'),
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
        // imageBuilder: (uri, title, alt) {
        //   return Image.network(uri.toString());
        // },
      ),
    );
  }
}
