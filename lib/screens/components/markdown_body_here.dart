import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MarkdownBodyHere extends StatelessWidget {
  final String data;

  const MarkdownBodyHere({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: data,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontStyle: FontStyle.normal,
          fontSize: 16,
          height: 1.6,
          color: Colors.black,
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4.0),
        ),
        code: TextStyle(
          backgroundColor: Colors.grey.shade100,
          color: Colors.purple.shade900,
          fontFamily: 'monospace',
        ),
        h1: const TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
        h2: const TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
      ),
      onTapLink: (text, url, title) {
        if (url != null) {
          launchUrlString(url); // Assuming you have the url_launcher package added
        }
      },
      imageBuilder: (uri, title, alt) {
        return Image.network(uri.toString());
      },
      selectable: true, // Allow users to select text
    );
  }
}
