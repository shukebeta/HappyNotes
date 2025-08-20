import 'package:flutter/material.dart';
import '../../../services/note_tag_service.dart';
import '../../../dependency_injection.dart';
import '../../../utils/util.dart';

class TagCloudController {
  final NoteTagService _noteTagService;

  TagCloudController({NoteTagService? noteTagService}) : _noteTagService = noteTagService ?? locator<NoteTagService>();

  Future<Map<String, int>> loadTagCloud(BuildContext context) async {
    final scaffoldContext = ScaffoldMessenger.of(context);
    try {
      final tagCloud = await _noteTagService.getMyTagCloud();
      return {for (var item in tagCloud) item.tag: item.count};
    } catch (error) {
      Util.showError(scaffoldContext, error.toString());
    } finally {}
    return {};
  }
}
