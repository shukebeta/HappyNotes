import 'package:flutter/foundation.dart';
import 'package:happy_notes/providers/provider_base.dart';
import 'package:happy_notes/services/note_tag_service.dart';

/// Pure TagProvider for shared tag cloud functionality
/// Provides tag cloud operations without note list management
class TagProvider extends AuthAwareProvider {
  final NoteTagService _noteTagService;

  TagProvider(this._noteTagService);

  // Tag cloud state
  Map<String, int> _tagCloud = {};
  Map<String, int> get tagCloud => _tagCloud;

  bool _isLoadingTagCloud = false;
  bool get isLoadingTagCloud => _isLoadingTagCloud;

  String? _error;
  String? get error => _error;

  DateTime? _lastTagCloudUpdate;
  bool get hasTagCloud => _tagCloud.isNotEmpty;
  bool get isTagCloudFresh => _lastTagCloudUpdate != null && 
    DateTime.now().difference(_lastTagCloudUpdate!).inMinutes < 5;

  // Tag cloud operations
  Future<void> loadTagCloud({bool forceRefresh = false}) async {
    if (!forceRefresh && isTagCloudFresh) return;

    await executeWithErrorHandling(
      operation: () async {
        final result = await _noteTagService.getMyTagCloud();
        final tagCloudMap = <String, int>{};
        for (final tagCount in result) {
          tagCloudMap[tagCount.tag] = tagCount.count;
        }
        _tagCloud = tagCloudMap;
        _lastTagCloudUpdate = DateTime.now();
        debugPrint('TagProvider: Loaded tag cloud with ${_tagCloud.length} tags');
        return tagCloudMap;
      },
      setLoading: (loading) => _isLoadingTagCloud = loading,
      setError: (error) => _error = error,
      operationName: 'load tag cloud',
    );
  }

  // Tag utility functions
  int getTagCount(String tag) => _tagCloud[tag] ?? 0;
  
  bool tagExists(String tag) => _tagCloud.containsKey(tag);
  
  List<String> getAllTags({bool sorted = true}) {
    final tags = _tagCloud.keys.toList();
    if (sorted) tags.sort();
    return tags;
  }
  
  List<MapEntry<String, int>> getTopTags(int limit) {
    final entries = _tagCloud.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  @override
  void clearAllData() {
    _tagCloud.clear();
    _lastTagCloudUpdate = null;
    _isLoadingTagCloud = false;
    _error = null;
    debugPrint('TagProvider: Cleared all tag cloud data');
  }

  @override
  Future<void> onLogin() async {
    // Tag cloud loading is manual - only load when explicitly requested
    debugPrint('TagProvider: User logged in, tag cloud remains passive');
  }
}