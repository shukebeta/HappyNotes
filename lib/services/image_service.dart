import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import '../app_config.dart';
import '../utils/util.dart';
import '../apis/file_uploader_api.dart';
import '../dependency_injection.dart';

class ImageService {
  final fileUploaderApi = locator<FileUploaderApi>();

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
        var text = '![image](${AppConfig.imgBaseUrl}/640${img['path']}${img['md5']}${img['fileExt']})';
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
      if (text != null) {
        onSuccess(text);
        return;
      }
    } catch (e) {
      print('Debug: Text clipboard access error: $e'); // Add logging for debugging
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
        }
      }
    } catch (e) {
      print('Debug: Image clipboard access error: $e'); // Add logging for debugging
    }

    // If we get here, neither text nor image was successfully processed
    onError('No valid content found in clipboard');
  }
}
