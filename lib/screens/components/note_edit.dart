// note_edit.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:happy_notes/apis/file_uploader_api.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:happy_notes/utils/happy_notes_prompts.dart';
import '../../app_config.dart';
import '../../dependency_injection.dart';
import '../../entities/note.dart';
import '../../models/note_model.dart';
import '../../utils/util.dart';

class NoteEdit extends StatefulWidget {
  final Note? note;

  const NoteEdit({
    Key? key,
    this.note,
  }) : super(key: key);

  @override
  NoteEditState createState() => NoteEditState();
}

class NoteEditState extends State<NoteEdit> {
  late String prompt;
  late TextEditingController controller;
  final fileUploaderApi = locator<FileUploaderApi>();

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
    final noteModel = context.read<NoteModel>();
    prompt = HappyNotesPrompts.getRandom(noteModel.isPrivate);

    // Delay the update to avoid triggering a rebuild during the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (noteModel.initialTag.isNotEmpty && widget.note == null) {
        noteModel.content = '#${noteModel.initialTag}\n';
        noteModel.initialTag = ''; // Reset after use
      } else if (widget.note != null) {
        noteModel.content = widget.note!.content;
      }

      // Set the initial text in the controller
      controller.text = noteModel.content;

      // Add listener to update controller.text when noteModel.content changes
      noteModel.addListener(() {
        if (noteModel.content != controller.text) {
          controller.text = noteModel.content;
        }
      });

      // Request focus and set prompt
      if (!AppConfig.isIOSWeb) {
        noteModel.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NoteModel>(
      builder: (context, noteModel, child) {
        return Column(
          children: [
            Expanded(
              child: _buildEditor(noteModel),
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    noteModel.togglePrivate();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      noteModel.isPrivate ? Icons.lock : Icons.lock_open,
                      color: noteModel.isPrivate ? Colors.blue : Colors.grey,
                      size: 24.0,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    noteModel.toggleMarkdown();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      "M↓",
                      style: TextStyle(
                        fontSize: 20.0,
                        color: noteModel.isMarkdown ? Colors.blue : Colors.grey,
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: noteModel.isMarkdown,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: IconButton(
                    onPressed: noteModel.isMarkdown ? () => _pickAndUploadImage(context, noteModel) : null,
                    icon: const Icon(Icons.add_photo_alternate),
                    iconSize: 24.0,
                    padding: const EdgeInsets.all(12.0),
                  ),
                ),
                Visibility(
                  // paste image from clipboard
                  visible: noteModel.isMarkdown && Util.isPasteBoardSupported(),
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: IconButton(
                    onPressed: () async {
                      noteModel.requestFocus();
                      await _getImageFromClipboard(context, noteModel);
                    },
                    icon: const Icon(Icons.paste),
                    iconSize: 24.0,
                    padding: const EdgeInsets.all(12.0),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditor(NoteModel noteModel) {
    return TextField(
      controller: controller,
      focusNode: noteModel.focusNode,
      keyboardType: TextInputType.multiline,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        hintText: prompt,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: noteModel.isPrivate ? Colors.blue : Colors.green,
            width: 2.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: noteModel.isPrivate ? Colors.blueAccent : Colors.greenAccent,
            width: 2.0,
          ),
        ),
      ),
      onChanged: (text) {
        noteModel.content = text;
      },
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context, NoteModel noteModel) async {
    final ScaffoldMessengerState scaffoldMessengerState = ScaffoldMessenger.of(context);
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      MultipartFile? imageFile;

      try {
        if (Util.isImageCompressionSupported()) {
          var imageData = await image.readAsBytes();
          Uint8List? compressedImage =
              await Util.compressImage(imageData, CompressFormat.jpeg, maxPixel: AppConfig.imageMaxDimension);
          if (compressedImage != null) {
            imageFile = MultipartFile.fromBytes(compressedImage, filename: image.name);
          }
        }

        if (imageFile == null) {
          final bytes = await image.readAsBytes();
          imageFile = MultipartFile.fromBytes(bytes, filename: image.name);
        }
        // Make the POST request if imageFile is not null
        Response response = await fileUploaderApi.upload(imageFile);
        if (response.statusCode == 200 && response.data['errorCode'] == 0) {
          var img = response.data['data'];
          var image = '![image](${AppConfig.imgBaseUrl}/640${img['path']}${img['md5']}${img['fileExt']})\n';
          noteModel.content += noteModel.content.isEmpty ? image : '\n$image';
        } else {
          throw Exception('Failed to upload image: ${response.statusCode}/${response.data['msg']}');
        }
      } catch (e) {
        Util.showError(scaffoldMessengerState, e.toString());
      }
    }
  }

  Future<void> _getImageFromClipboard(BuildContext context, NoteModel noteModel) async {
    var scaffoldMessengerState = ScaffoldMessenger.of(context);
    try {
      final imageBytes = await Pasteboard.image;
      if (imageBytes != null) {
        var image = await _getPossiblyCompressedMultipartFile(imageBytes);
        _uploadImage(image, noteModel);
      } else {
        Util.showInfo(scaffoldMessengerState, 'No image found in clipboard');
      }
    } catch (e) {
      Util.showError(scaffoldMessengerState, 'Error accessing clipboard: $e');
    }
  }

  Future<void> _uploadImage(MultipartFile imageFile, NoteModel noteModel) async {
    Response response = await fileUploaderApi.upload(imageFile);

    if (response.statusCode == 200 && response.data['errorCode'] == 0) {
      var img = response.data['data'];
      var imageMarkdown = '![image](${AppConfig.imgBaseUrl}/640${img['path']}${img['md5']}${img['fileExt']})\n';
      noteModel.content += noteModel.content.isEmpty ? imageMarkdown : '\n$imageMarkdown';
    } else {
      throw Exception('Failed to upload image: ${response.statusCode}/${response.data['msg']}');
    }
  }

  Future<MultipartFile> _getPossiblyCompressedMultipartFile(Uint8List imageBytes) async {
    var filename = 'image_${DateTime.now().millisecondsSinceEpoch}.jpeg';
    if (Util.isImageCompressionSupported()) {
      Uint8List? compressedImageBytes =
          await Util.compressImage(imageBytes, CompressFormat.jpeg, maxPixel: AppConfig.imageMaxDimension);
      if (compressedImageBytes != null) {
        return MultipartFile.fromBytes(compressedImageBytes, filename: filename);
      }
    }
    return MultipartFile.fromBytes(imageBytes, filename: filename);
  }
}
