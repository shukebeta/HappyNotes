import 'dart:typed_data';

// Stub implementation for non-web platforms
bool downloadImageOnWeb(Uint8List? imageBytes, String imageUrl) {
  // This should never be called on non-web platforms
  throw UnsupportedError('Web download not supported on this platform');
}