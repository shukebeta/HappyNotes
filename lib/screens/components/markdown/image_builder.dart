import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:photo_view/photo_view.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import '../../../services/image_service.dart';
import '../../../utils/util.dart';

// Conditional imports for web
import 'web_image_stub.dart'
    if (dart.library.html) 'web_image_impl.dart';

class ImageBuilder extends MarkdownElementBuilder {
  final BuildContext parentContext;
  final GetIt _locator = GetIt.instance;

  ImageBuilder(this.parentContext);

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final src = element.attributes['src'] ?? '';
    
    return createWebImage(
      src,
      () => _showFullScreenImage(src),
      () => _showSaveImageDialog(src),
    );
  }

  void _showFullScreenImage(String url) {
    if (kIsWeb) {
      _showWebFullScreenImage(url);
    } else {
      _showMobileFullScreenImage(url);
    }
  }

  void _showMobileFullScreenImage(String url) {
    final PhotoViewController controller = PhotoViewController();
    
    showDialog(
      context: parentContext,
      barrierDismissible: true,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: PhotoView(
                imageProvider: NetworkImage(url),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
                enableRotation: false, // Disable rotation like web version
                controller: controller, // Add controller for programmatic control
                // Restrict pan boundaries to prevent losing the image
                enablePanAlways: false, // Only allow pan when zoomed in
                strictScale: true, // Enforce scale limits
                tightMode: true, // Constrain panning to image boundaries
                filterQuality: FilterQuality.high, // Better image quality
                loadingBuilder: (context, event) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.error, color: Colors.white, size: 48),
                ),
              ),
            ),
            // Double-tap to reset and long-press for save functionality
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTap: () {
                  // Reset zoom and position like web version
                  controller.reset();
                },
                onLongPress: () => _showSaveImageDialog(url),
                child: Container(), // Transparent container for gesture detection
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWebFullScreenImage(String url) {
    showDialog(
      context: parentContext,
      barrierDismissible: true,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: createWebImage(
                url,
                () {}, // No tap action in fullscreen
                () {}, // No long press action in fullscreen
                isFullScreen: true,
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSaveImageDialog(String url) {
    showDialog(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: Text(kIsWeb ? 'Open Image' : 'Save Image'),
        content: Text(kIsWeb 
          ? 'Open this image in browser?' 
          : 'Save this image to your device gallery?'),
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
            child: Text(kIsWeb ? 'Open' : 'Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImage(String url) async {
    final imageService = _locator<ImageService>();
    final result = await imageService.saveImageToGallery(url);

    if (parentContext.mounted) {
      final message = result 
        ? (kIsWeb ? 'Image opened in browser!' : 'Image saved!') 
        : (kIsWeb ? 'Failed to open image' : 'Failed to save image');
      Util.showInfo(ScaffoldMessenger.of(parentContext), message);
    }
  }
}
