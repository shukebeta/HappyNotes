import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:gal/gal.dart';
import '../app_config.dart';
import '../utils/util.dart';
import 'seq_logger.dart';
import '../apis/file_uploader_api.dart';
import '../dependency_injection.dart';

// Conditional imports for web download functionality
import 'web_download_stub.dart' if (dart.library.html) 'web_download_impl.dart';

class ImageService {
  final fileUploaderApi = locator<FileUploaderApi>();

  /// Saves a network image to the device's gallery
  Future<bool> saveImageToGallery(String imageUrl) async {
    try {
      if (kIsWeb) {
        // Web: Download directly from the image source without API call
        return downloadImageOnWeb(null, imageUrl);
      } else {
        // Mobile: Download image bytes and save to gallery
        final response = await Dio().get(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        final imageBytes = Uint8List.fromList(response.data);

        if (!await Gal.hasAccess()) {
          await Gal.requestAccess();
        }
        await Gal.putImageBytes(imageBytes);
        return true;
      }
    } catch (e) {
      SeqLogger.severe('Failed to save image to gallery', e);
      return false;
    }
  }

  Future<MultipartFile?> compressImageIfNeeded(Uint8List imageBytes, String filename) async {
    if (Util.isImageCompressionSupported()) {
      Uint8List? compressedImageBytes = await Util.compressImage(
        imageBytes,
        CompressFormat.jpeg,
        maxPixel: AppConfig.imageMaxDimension,
      );
      if (compressedImageBytes != null) {
        return MultipartFile.fromBytes(compressedImageBytes, filename: filename);
      }
    }
    return MultipartFile.fromBytes(imageBytes, filename: filename);
  }

  Future<MultipartFile?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      return compressImageIfNeeded(bytes, image.name);
    }
    return null;
  }

  Future<void> uploadImage(MultipartFile imageFile, Function(String) onSuccess, Function(String) onError) async {
    try {
      Response response = await fileUploaderApi.upload(imageFile);
      if (response.statusCode == 200 && response.data['errorCode'] == 0) {
        var img = response.data['data'];
        var text = '![image](${AppConfig.imgBaseUrl}/${AppConfig.defaultDisplayImageWidth}${img['path']}${img['md5']}${img['fileExt']})';
        onSuccess(text);
      } else {
        onError('Failed to upload image ${imageFile.filename}: ${response.data['msg']} (${response.statusCode})');
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Paste image or text from Clipboard
  Future<void> pasteFromClipboard(Function(String) onSuccess, Function(String) onError) async {
    // First try to get text since it's more common and faster
    try {
      String? text = await Pasteboard.text;
      if (text != null && text.isNotEmpty) {
        onSuccess(text);
        return;
      }
    } catch (e) {
      SeqLogger.fine('Clipboard text access failed (expected fallback)', e);
    }

    // If no text found, try image
    try {
      final imageBytes = await Pasteboard.image;
      if (imageBytes != null) {
        final filename = 'image_${DateTime.now().millisecondsSinceEpoch}.jpeg';
        final imageFile = await compressImageIfNeeded(imageBytes, filename);
        if (imageFile != null) {
          await uploadImage(imageFile, onSuccess, onError);
          return;
        } else {
          SeqLogger.warning('Image compression failed or returned null');
        }
      } else {
        SeqLogger.info('Clipboard image is null (no image in clipboard)');
      }
    } catch (e) {
      SeqLogger.severe('Image clipboard access error', e);
      if (e.toString().contains('JSObject') || e.toString().contains('TypeError')) {
        onError(
            'Clipboard access failed. This might be due to browser restrictions or permissions. Please ensure clipboard access is enabled in your browser settings.');
        return;
      }
    }

    // If we get here, neither text nor image was successfully processed
    onError(
        'No valid content found in clipboard. Check debug logs for more details or ensure clipboard access permissions are granted in your browser.');
  }
}
