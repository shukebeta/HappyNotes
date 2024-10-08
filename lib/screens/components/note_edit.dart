// note_edit.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:happy_notes/apis/file_uploader_api.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:happy_notes/utils/happy_notes_prompts.dart';
import '../../app_config.dart';
import '../../dependency_injection.dart';
import '../../dio_client.dart';
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Distribute space evenly
              children: [
                GestureDetector(
                  onTap: () {
                    noteModel.isPrivate = !noteModel.isPrivate;
                  },
                  child: Icon(
                    noteModel.isPrivate ? Icons.lock : Icons.lock_open,
                    color: noteModel.isPrivate ? Colors.blue : Colors.grey,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    noteModel.isMarkdown = !noteModel.isMarkdown;
                  },
                  child: Text(
                    "M↓",
                    style: TextStyle(
                      fontSize: 20.0,
                      color: noteModel.isMarkdown ? Colors.blue : Colors.grey,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _pickAndUploadImage(context, noteModel), // Method to handle image picking and upload
                  icon: const Icon(Icons.add_photo_alternate),
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
    final fileUploaderApi = locator<FileUploaderApi>();

    if (image != null) {
      try {
        MultipartFile? imageFile;
        if (_platformSupportCompress()) {
          // always use CompressFormat.jpeg as it has best compatibility
          Uint8List? compressedImage = await _compressImage(image, CompressFormat.jpeg, maxPixel: 900);
          if (compressedImage != null) {
            imageFile = MultipartFile.fromBytes(compressedImage, filename: image.name);
          }
        }
        imageFile ??= MultipartFile.fromBytes(await image.readAsBytes(), filename: image.name);
        // Make the POST request
        Response response = await fileUploaderApi.upload(imageFile);

        if (response.statusCode == 200 && response.data['errorCode'] == 0) {
          var img = response.data['data'];
          noteModel.content += '![image](${img['url']})';
        } else {
          throw Exception('Failed to upload image: ${response.statusCode}');
        }
      } catch (e) {
        Util.showError(scaffoldMessengerState, e.toString());
      }
    }
  }

  bool _platformSupportCompress() {
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<Uint8List?> _compressImage(
    XFile image,
    CompressFormat format, {
    int maxPixel = 3333,
  }) async {
    var imageData = await image.readAsBytes();
    return await FlutterImageCompress.compressWithList(
      imageData,
      minWidth: maxPixel,
      minHeight: maxPixel,
      quality: 85,
      format: format,
    );
  }
}
