import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/memories_provider.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';

import 'notes_provider_test.mocks.dart';

void main() {
  group('MemoriesProvider Tests', () {
    late MemoriesProvider memoriesProvider;
    late MockNotesService mockNotesService;

    setUp(() {
      mockNotesService = MockNotesService();
      memoriesProvider = MemoriesProvider(mockNotesService);
    });

    group('Initialization', () {
      test('should initialize with empty state', () {
        expect(memoriesProvider.memories, isEmpty);
        expect(memoriesProvider.isLoading, isFalse);
        expect(memoriesProvider.error, isNull);
        expect(memoriesProvider.hasFreshCache, isFalse);
        expect(memoriesProvider.cacheAgeMinutes, equals(-1));
      });
    });

    group('Load memories functionality', () {
      test('should load memories successfully', () async {
        final notes = [
          Note(id: 1, content: 'Memory 1', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
          Note(id: 2, content: 'Memory 2', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 2);
        
        when(mockNotesService.memories())
            .thenAnswer((_) async => result);

        await memoriesProvider.loadMemories();

        expect(memoriesProvider.memories, equals(notes));
        expect(memoriesProvider.error, isNull);
        expect(memoriesProvider.hasFreshCache, isTrue);
        expect(memoriesProvider.cacheAgeMinutes, equals(0));
      });

      test('should use cached data when not forcing refresh', () async {
        final notes = [
          Note(id: 1, content: 'Memory 1', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 1);
        
        when(mockNotesService.memories())
            .thenAnswer((_) async => result);

        // First load
        await memoriesProvider.loadMemories();
        
        // Second load without force refresh
        await memoriesProvider.loadMemories(forceRefresh: false);

        // Should only call service once
        verify(mockNotesService.memories()).called(1);
      });

      test('should refresh data when forcing refresh', () async {
        final notes = [
          Note(id: 1, content: 'Memory 1', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 1);
        
        when(mockNotesService.memories())
            .thenAnswer((_) async => result);

        // First load
        await memoriesProvider.loadMemories();
        
        // Second load with force refresh
        await memoriesProvider.loadMemories(forceRefresh: true);

        // Should call service twice
        verify(mockNotesService.memories()).called(2);
      });

      test('should handle load errors', () async {
        when(mockNotesService.memories())
            .thenThrow(Exception('Load failed'));

        await memoriesProvider.loadMemories();

        expect(memoriesProvider.memories, isEmpty);
        expect(memoriesProvider.error, contains('Load failed'));
        expect(memoriesProvider.hasFreshCache, isFalse);
      });
    });

    group('Delete functionality', () {
      test('should delete note successfully', () async {
        // Setup initial memories
        final notes = [
          Note(id: 1, content: 'Memory 1', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
          Note(id: 2, content: 'Memory 2', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 2);
        
        when(mockNotesService.memories())
            .thenAnswer((_) async => result);
        when(mockNotesService.delete(1))
            .thenAnswer((_) async => 1);

        // Load memories first
        await memoriesProvider.loadMemories();
        
        // Delete note
        final deleteResult = await memoriesProvider.deleteNote(1);

        expect(deleteResult, isTrue);
        expect(memoriesProvider.memories.length, equals(1));
        expect(memoriesProvider.memories.first.id, equals(2));
      });

      test('should handle delete errors', () async {
        when(mockNotesService.delete(any))
            .thenThrow(Exception('Delete failed'));

        final deleteResult = await memoriesProvider.deleteNote(1);

        expect(deleteResult, isFalse);
        expect(memoriesProvider.error, contains('Delete failed'));
      });
    });

    group('Cache functionality', () {
      test('should detect fresh cache correctly', () async {
        final notes = [
          Note(id: 1, content: 'Memory 1', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 1);
        
        when(mockNotesService.memories())
            .thenAnswer((_) async => result);

        await memoriesProvider.loadMemories();

        expect(memoriesProvider.hasFreshCache, isTrue);
        expect(memoriesProvider.cacheAgeMinutes, equals(0));
      });

      test('should report cache age correctly', () async {
        final notes = [
          Note(id: 1, content: 'Memory 1', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 1);
        
        when(mockNotesService.memories())
            .thenAnswer((_) async => result);

        await memoriesProvider.loadMemories();

        // Initially should be 0 minutes old
        expect(memoriesProvider.cacheAgeMinutes, equals(0));
      });
    });

    group('Refresh functionality', () {
      test('should refresh memories', () async {
        final notes = [
          Note(id: 1, content: 'Memory 1', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 1);
        
        when(mockNotesService.memories())
            .thenAnswer((_) async => result);

        await memoriesProvider.refreshMemories();

        expect(memoriesProvider.memories, equals(notes));
        verify(mockNotesService.memories()).called(1);
      });
    });

    group('Auth aware functionality', () {
      test('should clear all data on clearAllData', () {
        memoriesProvider.clearAllData();

        expect(memoriesProvider.memories, isEmpty);
        expect(memoriesProvider.isLoading, isFalse);
        expect(memoriesProvider.error, isNull);
      });

      test('should load memories on login', () async {
        final notes = [
          Note(id: 1, content: 'Memory 1', isPrivate: false, userId: 1, isLong: false, isMarkdown: false, createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000),
        ];
        final result = NotesResult(notes, 1);
        
        when(mockNotesService.memories())
            .thenAnswer((_) async => result);

        await memoriesProvider.onLogin();

        expect(memoriesProvider.memories, equals(notes));
      });
    });
  });
}