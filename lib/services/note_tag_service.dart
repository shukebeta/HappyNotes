import '../apis/note_tag_api.dart';
import '../exceptions/api_exception.dart';

class NoteTagService {
  final NoteTagApi _noteTagApi;

  NoteTagService({required NoteTagApi noteTagApi}) : _noteTagApi = noteTagApi;

  Future<Map<String, int>> getMyTagCloud() async {
    var apiResult = (await _noteTagApi.getMyTagCloud()).data;
    if (!apiResult['successful']) throw ApiException(apiResult);
    return {
      for (var item in apiResult['data'])
        if (!(item['tag'] as String).startsWith('@')) item['tag'] as String: item['count'] as int
    };
  }
}
