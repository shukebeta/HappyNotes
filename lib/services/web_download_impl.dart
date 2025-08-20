// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:typed_data';
import 'dart:html' as html;
import '../app_config.dart';

// Web implementation for downloading/saving images
bool downloadImageOnWeb(Uint8List? imageBytes, String imageUrl) {
  try {
    // Check if this is iOS web (Safari or Chrome)
    if (AppConfig.isIOSWeb) {
      // For iOS web, we don't open a new window
      // Instead, the user should use the long-press context menu to save to Photos
      // We just return true to indicate the save option was triggered
      return true;
    }

    // For other browsers, use standard download approach
    if (imageBytes != null) {
      return _downloadImageWithBlob(imageBytes, imageUrl);
    }

    // Fallback for non-iOS browsers: open in new tab
    html.window.open(imageUrl, '_blank');
    return true;
  } catch (e) {
    return false;
  }
}

bool _downloadImageWithBlob(Uint8List imageBytes, String originalUrl) {
  try {
    // Create blob from image bytes
    final blob = html.Blob([imageBytes], 'image/jpeg');
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Create anchor element with download attribute
    final anchor = html.AnchorElement()
      ..href = url
      ..download = _getImageFileName(originalUrl)
      ..style.display = 'none';

    // Add to document, click, and remove
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);

    // Clean up object URL
    html.Url.revokeObjectUrl(url);

    return true;
  } catch (e) {
    return false;
  }
}

String _getImageFileName(String imageUrl) {
  try {
    final uri = Uri.parse(imageUrl);
    String filename = uri.pathSegments.last;

    // If no extension, add .jpg
    if (!filename.contains('.')) {
      filename += '.jpg';
    }

    // If filename is empty or just extension, use default
    if (filename.isEmpty || filename.startsWith('.')) {
      filename = 'image.jpg';
    }

    return filename;
  } catch (e) {
    return 'image.jpg';
  }
}
