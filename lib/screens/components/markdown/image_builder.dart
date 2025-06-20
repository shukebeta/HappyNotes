import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:photo_view/photo_view.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:get_it/get_it.dart';
import '../../../services/image_service.dart';

class ImageBuilder extends MarkdownElementBuilder {
  final BuildContext parentContext;
  final GetIt _locator = GetIt.instance;

  ImageBuilder(this.parentContext);

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final src = element.attributes['src'] ?? '';
    return GestureDetector(
      child: Image.network(src),
      onTap: () => _showFullScreenImage(src),
      onLongPress: () => _showSaveImageDialog(src),
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

  void _showSaveImageDialog(String url) {
    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Image'),
        content: const Text('Save this image to your device gallery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _saveImage(url);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImage(String url) async {
    final imageService = _locator<ImageService>();
    final result = await imageService.saveImageToGallery(url);

    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(content: Text(result ? 'Image saved!' : 'Failed to save image')),
    );
  }
}
