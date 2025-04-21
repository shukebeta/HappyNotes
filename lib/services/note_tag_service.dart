import '../apis/note_tag_api.dart';
import '../exceptions/api_exception.dart';
import '../models/tag_count.dart';

class NoteTagService {
  final NoteTagApi _noteTagApi;

  NoteTagService({required NoteTagApi noteTagApi}) : _noteTagApi = noteTagApi;

  Future<List<TagCount>> getMyTagCloud() async {
    var apiResult = (await _noteTagApi.getMyTagCloud()).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return [
      for (var item in apiResult['data'])
        if (!(item['tag'] as String).startsWith('@'))
          TagCount(tag: item['tag'] as String, count: item['count'] as int)
    ];
  }
}
