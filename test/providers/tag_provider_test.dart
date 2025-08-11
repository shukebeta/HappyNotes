import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/tag_provider.dart';
import 'package:happy_notes/services/note_tag_service.dart';
import 'package:happy_notes/models/tag_count.dart';

class MockNoteTagService extends Mock implements NoteTagService {
  @override
  Future<List<TagCount>> getMyTagCloud() => super.noSuchMethod(
    Invocation.method(#getMyTagCloud, []),
    returnValue: Future.value(<TagCount>[]),
  );
}

void main() {
  group('TagProvider Tests', () {
    late TagProvider tagProvider;
    late MockNoteTagService mockNoteTagService;

    setUp(() {
      mockNoteTagService = MockNoteTagService();
      tagProvider = TagProvider(mockNoteTagService);
    });

    group('Initialization', () {
      test('should initialize with empty state', () {
        expect(tagProvider.tagCloud, isEmpty);
        expect(tagProvider.isLoadingTagCloud, isFalse);
        expect(tagProvider.hasTagCloud, isFalse);
        expect(tagProvider.isTagCloudFresh, isFalse);
        expect(tagProvider.error, isNull);
      });
    });

    group('Tag cloud functionality', () {
      test('should load tag cloud successfully', () async {
        final testTagCounts = [
          TagCount(tag: 'flutter', count: 5),
          TagCount(tag: 'dart', count: 3),
          TagCount(tag: 'mobile', count: 2),
        ];
        final expectedTagCloud = {'flutter': 5, 'dart': 3, 'mobile': 2};
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => testTagCounts);

        await tagProvider.loadTagCloud();

        expect(tagProvider.tagCloud, equals(expectedTagCloud));
        expect(tagProvider.hasTagCloud, isTrue);
        expect(tagProvider.isTagCloudFresh, isTrue);
        expect(tagProvider.isLoadingTagCloud, isFalse);
        expect(tagProvider.error, isNull);
      });

      test('should use cached data when not forcing refresh', () async {
        final testTagCounts = [
          TagCount(tag: 'flutter', count: 5),
          TagCount(tag: 'dart', count: 3),
        ];
        final expectedTagCloud = {'flutter': 5, 'dart': 3};
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => testTagCounts);

        // First load
        await tagProvider.loadTagCloud();
        expect(tagProvider.tagCloud, equals(expectedTagCloud));

        // Second load without force refresh - should not call service again
        await tagProvider.loadTagCloud();
        verify(mockNoteTagService.getMyTagCloud()).called(1);
      });

      test('should refresh data when forcing refresh', () async {
        final initialTagCounts = [TagCount(tag: 'flutter', count: 5)];
        final updatedTagCounts = [
          TagCount(tag: 'flutter', count: 6),
          TagCount(tag: 'dart', count: 2),
        ];
        final initialTagCloud = {'flutter': 5};
        final updatedTagCloud = {'flutter': 6, 'dart': 2};
        
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => initialTagCounts);

        // First load
        await tagProvider.loadTagCloud();
        expect(tagProvider.tagCloud, equals(initialTagCloud));

        // Update mock to return different data
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => updatedTagCounts);

        // Force refresh should call service again
        await tagProvider.loadTagCloud(forceRefresh: true);
        expect(tagProvider.tagCloud, equals(updatedTagCloud));
        verify(mockNoteTagService.getMyTagCloud()).called(2);
      });

      test('should handle load errors', () async {
        when(mockNoteTagService.getMyTagCloud())
            .thenThrow(Exception('Network error'));

        await tagProvider.loadTagCloud();

        expect(tagProvider.tagCloud, isEmpty);
        expect(tagProvider.hasTagCloud, isFalse);
        expect(tagProvider.isLoadingTagCloud, isFalse);
        expect(tagProvider.error, contains('Network error'));
      });
    });

    group('Tag utility functions', () {
      setUp(() async {
        final testTagCounts = [
          TagCount(tag: 'flutter', count: 5),
          TagCount(tag: 'dart', count: 3),
          TagCount(tag: 'mobile', count: 2),
          TagCount(tag: 'web', count: 1),
        ];
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => testTagCounts);
        await tagProvider.loadTagCloud();
      });

      test('should get tag count correctly', () {
        expect(tagProvider.getTagCount('flutter'), equals(5));
        expect(tagProvider.getTagCount('dart'), equals(3));
        expect(tagProvider.getTagCount('nonexistent'), equals(0));
      });

      test('should check if tag exists', () {
        expect(tagProvider.tagExists('flutter'), isTrue);
        expect(tagProvider.tagExists('dart'), isTrue);
        expect(tagProvider.tagExists('nonexistent'), isFalse);
      });

      test('should return all tags sorted', () {
        final allTags = tagProvider.getAllTags();
        expect(allTags, equals(['dart', 'flutter', 'mobile', 'web']));
      });

      test('should return top tags by count', () {
        final topTags = tagProvider.getTopTags(2);
        expect(topTags.length, equals(2));
        expect(topTags[0].key, equals('flutter'));
        expect(topTags[0].value, equals(5));
        expect(topTags[1].key, equals('dart'));
        expect(topTags[1].value, equals(3));
      });
    });

    group('Auth aware functionality', () {
      test('should clear all data on clearAllData', () async {
        // Load some data first
        final testTagCounts = [
          TagCount(tag: 'flutter', count: 5),
          TagCount(tag: 'dart', count: 3),
        ];
        when(mockNoteTagService.getMyTagCloud())
            .thenAnswer((_) async => testTagCounts);
        await tagProvider.loadTagCloud();
        expect(tagProvider.hasTagCloud, isTrue);

        // Clear data
        tagProvider.clearAllData();

        expect(tagProvider.tagCloud, isEmpty);
        expect(tagProvider.hasTagCloud, isFalse);
        expect(tagProvider.isTagCloudFresh, isFalse);
        expect(tagProvider.isLoadingTagCloud, isFalse);
        expect(tagProvider.error, isNull);
      });

      test('should remain passive on login', () async {
        // onLogin should not automatically load tag cloud
        await tagProvider.onLogin();
        
        expect(tagProvider.tagCloud, isEmpty);
        expect(tagProvider.hasTagCloud, isFalse);
        verifyNever(mockNoteTagService.getMyTagCloud());
      });
    });
  });
}