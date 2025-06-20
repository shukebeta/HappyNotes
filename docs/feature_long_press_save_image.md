# Long Press to Save Photo Feature Implementation Plan

## Overview
This feature allows users to long-press on images in markdown notes to save them to their device's gallery.

## Implementation Steps

### 1. Update ImageBuilder (`lib/screens/components/markdown/image_builder.dart`)
- Add `onLongPress` handler to GestureDetector
- Show context menu with "Save Image" option
- Implement image saving logic

```dart
// Updated ImageBuilder
class ImageBuilder extends MarkdownElementBuilder {
  // ... existing code ...

  @override
  Widget visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final src = element.attributes['src'] ?? '';
    return GestureDetector(
      child: Image.network(src),
      onTap: () => _showFullScreenImage(src),
      onLongPress: () => _showSaveImageDialog(src),
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
            onPressed: () {
              Navigator.pop(ctx);
              _saveImage(url);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveImage(String url) async {
    // Implement saving logic using ImageService
    final imageService = locator<ImageService>();
    final result = await imageService.saveImageToGallery(url);
    
    ScaffoldMessenger.of(parentContext).showSnackBar(
      SnackBar(content: Text(result ? 'Image saved!' : 'Failed to save image')),
    );
  }
}
```

### 2. Update ImageService (`lib/services/image_service.dart`)
- Add `saveImageToGallery` method
- Implement platform-specific saving

```dart
class ImageService {
  Future<bool> saveImageToGallery(String imageUrl) async {
    try {
      // Check storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) return false;

      // Download image
      final response = await Dio().get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // Save to gallery
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(response.data),
        quality: 100,
      );
      
      return result['isSuccess'] == true;
    } catch (e) {
      AppLogger.e('Error saving image: $e');
      return false;
    }
  }
}
```

### 3. Add Dependencies (`pubspec.yaml`)
```yaml
dependencies:
  image_gallery_saver: ^2.0.0
  permission_handler: ^10.0.0
```

### 4. Permission Handling (Android)
Add required permission to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## Testing Plan
1. Verify long-press gesture shows save dialog
2. Test image saving functionality
3. Verify permission handling
4. Check user feedback (snackbars)
5. Validate on both Android and iOS

## Timeline
- Implementation: 2 hours
- Testing: 1 hour