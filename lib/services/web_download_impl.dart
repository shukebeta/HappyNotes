import 'dart:typed_data';
import 'dart:html' as html;

// Web implementation for opening images in browser
bool downloadImageOnWeb(Uint8List? imageBytes, String imageUrl) {
  try {
    // Simply open the image in a new tab for web users
    html.window.open(imageUrl, '_blank');
    return true;
  } catch (e) {
    print('Error opening image on web: $e');
    return false;
  }
}