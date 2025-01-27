import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:photo_view/photo_view.dart';
import 'package:markdown/markdown.dart' as md;

class ImageBuilder extends MarkdownElementBuilder {
  final BuildContext parentContext;

  ImageBuilder(this.parentContext);

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final src = element.attributes['src'] ?? '';
    return GestureDetector(
      child: Image.network(src),
      onTap: () => _showFullScreenImage(src),
    );
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: parentContext,
      builder: (ctx) => Dialog(
        child: PhotoView(
          imageProvider: NetworkImage(url),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 4,
        ),
      ),
    );
  }
}
