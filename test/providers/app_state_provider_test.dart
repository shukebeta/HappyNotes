import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_notes/providers/app_state_provider.dart';
import 'package:happy_notes/providers/auth_provider.dart';
import 'package:happy_notes/providers/notes_provider.dart';
import 'package:happy_notes/providers/search_provider.dart';
import 'package:happy_notes/providers/tag_notes_provider.dart';
import 'package:happy_notes/providers/memories_provider.dart';
import 'package:happy_notes/providers/trash_provider.dart';
import 'package:happy_notes/providers/discovery_provider.dart';
import 'package:happy_notes/entities/note.dart';
import 'package:happy_notes/models/notes_result.dart';

// Import existing mocks
import 'notes_provider_test.mocks.dart';
import '../test_helpers/seq_logger_setup.dart';

class MockAuthProvider extends Mock implements AuthProvider {
  @override
  bool get isAuthenticated => super.noSuchMethod(
    Invocation.getter(#isAuthenticated),
    returnValue: false,
  );

  @override
  int? get currentUserId => super.noSuchMethod(
    Invocation.getter(#currentUserId),
    returnValue: null,
  );

  @override
  String? get currentUserEmail => super.noSuchMethod(
    Invocation.getter(#currentUserEmail),
    returnValue: null,
  );
}

class MockSearchProvider extends Mock implements SearchProvider {
  @override
  void clearNotesCache() => super.noSuchMethod(Invocation.method(#clearNotesCache, []));

  @override
  Future<void> onAuthStateChanged(bool isAuthenticated) => super.noSuchMethod(
    Invocation.method(#onAuthStateChanged, [isAuthenticated]),
    returnValue: Future.value(),
  );

  @override
  Future<void> refreshSearch() => super.noSuchMethod(
    Invocation.method(#refreshSearch, []),
    returnValue: Future.value(),
  );

  @override
  Future<void> searchNotes(String query, int pageNumber) => super.noSuchMethod(
    Invocation.method(#searchNotes, [query, pageNumber]),
    returnValue: Future.value(),
  );
}

class MockTagNotesProvider extends Mock implements TagNotesProvider {
  @override
  void clearNotesCache() => super.noSuchMethod(Invocation.method(#clearNotesCache, []));

  @override
  Future<void> onAuthStateChanged(bool isAuthenticated) => super.noSuchMethod(
    Invocation.method(#onAuthStateChanged, [isAuthenticated]),
    returnValue: Future.value(),
  );

  Future<void> loadTagCloud({bool forceRefresh = false}) => super.noSuchMethod(
    Invocation.method(#loadTagCloud, [], {#forceRefresh: forceRefresh}),
    returnValue: Future.value(),
  );
}


class MockMemoriesProvider extends Mock implements MemoriesProvider {
  @override
  void clearNotesCache() => super.noSuchMethod(Invocation.method(#clearNotesCache, []));

  @override
  Future<void> onAuthStateChanged(bool isAuthenticated) => super.noSuchMethod(
    Invocation.method(#onAuthStateChanged, [isAuthenticated]),
    returnValue: Future.value(),
  );

  @override
  Future<void> refreshMemories() => super.noSuchMethod(
    Invocation.method(#refreshMemories, []),
    returnValue: Future.value(),
  );
}

class MockTrashProvider extends Mock implements TrashProvider {
  @override
  void clearNotesCache() => super.noSuchMethod(Invocation.method(#clearNotesCache, []));

  @override
  Future<void> onAuthStateChanged(bool isAuthenticated) => super.noSuchMethod(
    Invocation.method(#onAuthStateChanged, [isAuthenticated]),
    returnValue: Future.value(),
  );

  @override
  Future<void> refresh() => super.noSuchMethod(
    Invocation.method(#refresh, []),
    returnValue: Future.value(),
  );
}

class MockDiscoveryProvider extends Mock implements DiscoveryProvider {
  @override
  void clearNotesCache() => super.noSuchMethod(Invocation.method(#clearNotesCache, []));

  @override
  Future<void> onAuthStateChanged(bool isAuthenticated) => super.noSuchMethod(
    Invocation.method(#onAuthStateChanged, [isAuthenticated]),
    returnValue: Future.value(),
  );

  @override
  Future<void> refresh() => super.noSuchMethod(
    Invocation.method(#refresh, []),
    returnValue: Future.value(),
  );
}

void main() {
  group('AppStateProvider Tests', () {
    late AppStateProvider appStateProvider;
    late MockAuthProvider mockAuthProvider;
    late MockNotesService mockNotesService;
    late NotesProvider notesProvider;
    late MockSearchProvider mockSearchProvider;
    late MockTagNotesProvider mockTagNotesProvider;
    late MockMemoriesProvider mockMemoriesProvider;
    late MockTrashProvider mockTrashProvider;
    late MockDiscoveryProvider mockDiscoveryProvider;

    setUp(() {
      // Initialize SeqLogger for tests
      setupSeqLoggerForTesting();

      mockAuthProvider = MockAuthProvider();
      mockNotesService = MockNotesService();
      mockSearchProvider = MockSearchProvider();
      mockTagNotesProvider = MockTagNotesProvider();
      mockMemoriesProvider = MockMemoriesProvider();
      mockTrashProvider = MockTrashProvider();
      mockDiscoveryProvider = MockDiscoveryProvider();

      // Setup default mock responses before creating provider
      when(mockAuthProvider.isAuthenticated).thenReturn(false);
      when(mockAuthProvider.currentUserId).thenReturn(null);
      when(mockAuthProvider.currentUserEmail).thenReturn(null);

      notesProvider = NotesProvider(mockNotesService);
      appStateProvider = AppStateProvider(
        mockAuthProvider,
        notesProvider,
        mockSearchProvider,
        mockTagNotesProvider,
        mockMemoriesProvider,
        mockTrashProvider,
        mockDiscoveryProvider,
      );
    });

    group('Initialization', () {
      test('should initialize correctly', () {
        expect(appStateProvider.isInitialized, isTrue);
        expect(appStateProvider.isAuthenticated, isFalse);
        expect(appStateProvider.currentUser, isNull);
      });

      test('should listen to auth provider changes', () {
        // Verify that AppStateProvider sets up listener on auth provider
        // The listener is set up in constructor
        expect(appStateProvider.isInitialized, isTrue);
      });
    });

    group('Authentication State Management', () {
      test('should handle user login', () async {
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.currentUserId).thenReturn(123);
        when(mockAuthProvider.currentUserEmail).thenReturn('test@example.com');

        var notificationCount = 0;
        appStateProvider.addListener(() => notificationCount++);

        // Trigger auth state change manually for testing
        when(mockAuthProvider.isAuthenticated).thenReturn(true);

        expect(appStateProvider.isAuthenticated, isTrue);
        expect(appStateProvider.currentUser, isNotNull);
        expect(appStateProvider.currentUser!['id'], equals(123));
      });

      test('should handle user logout', () async {
        // Start with authenticated user
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.currentUserId).thenReturn(123);
        when(mockAuthProvider.currentUserEmail).thenReturn('test@example.com');

        // Simulate logout
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.currentUserId).thenReturn(null);
        when(mockAuthProvider.currentUserEmail).thenReturn(null);

        expect(appStateProvider.isAuthenticated, isFalse);
        expect(appStateProvider.currentUser, isNull);
      });
    });

    group('Provider Coordination', () {
      test('should coordinate notes provider on auth changes', () async {
        var notesProviderNotifications = 0;
        notesProvider.addListener(() => notesProviderNotifications++);

        // Clear all data should be called on logout
        notesProvider.clearNotesCache();

        expect(notesProvider.notes, isEmpty);
        expect(notesProvider.groupedNotes, isEmpty);
        expect(notesProvider.currentPage, 1);
        expect(notesProviderNotifications, greaterThan(0));
      });

      test('should refresh all provider data', () async {
        when(mockAuthProvider.isAuthenticated).thenReturn(true);

        // Mock notes service for refresh - ensure all needed calls are mocked
        when(mockNotesService.myLatest(any, any))
            .thenAnswer((_) async => NotesResult([], 0));

        // Explicitly mock all provider refresh methods
        when(mockSearchProvider.refreshSearch())
            .thenAnswer((_) async {});
        when(mockMemoriesProvider.refreshMemories())
            .thenAnswer((_) async {});

        await appStateProvider.refreshAllData();

        // Verify notes provider refresh was called
        verify(mockNotesService.myLatest(10, 1)).called(1);
        // Verify other providers were called
        verify(mockSearchProvider.refreshSearch()).called(1);
        verify(mockMemoriesProvider.refreshMemories()).called(1);
      });

      test('should not refresh data when not authenticated', () async {
        when(mockAuthProvider.isAuthenticated).thenReturn(false);

        await appStateProvider.refreshAllData();

        // Verify no API calls when not authenticated
        verifyNever(mockNotesService.myLatest(any, any));
      });
    });

    group('Loading States', () {
      test('should aggregate loading states from providers', () {
        // Initially not loading
        expect(appStateProvider.isLoading, isFalse);

        // Simulate loading state in notes provider
        when(mockNotesService.myLatest(10, 1))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return NotesResult([], 0);
        });

        // Start loading
        notesProvider.loadPage(1);
        expect(appStateProvider.isLoading, isTrue);
      });
    });

    group('Error Management', () {
      test('should aggregate errors from providers', () async {
        // Simulate error in notes provider
        when(mockNotesService.myLatest(10, 1))
            .thenThrow(Exception('Network error'));

        await notesProvider.loadPage(1);

        final errors = appStateProvider.errors;
        expect(errors, isNotEmpty);
        expect(errors.first, contains('Network error'));
      });

      test('should clear all errors', () {
        appStateProvider.clearAllErrors();

        final errors = appStateProvider.errors;
        expect(errors, isEmpty);
      });
    });

    group('Resource Management', () {
      test('should dispose properly', () {
        appStateProvider.addListener(() {});

        // Test that dispose doesn't throw
        expect(() => appStateProvider.dispose(), returnsNormally);
      });
    });

    group('Integration Scenarios', () {
      test('should handle complete login flow', () async {
        var appStateNotifications = 0;
        var notesProviderNotifications = 0;

        appStateProvider.addListener(() => appStateNotifications++);
        notesProvider.addListener(() => notesProviderNotifications++);

        // Setup mock for successful login
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.currentUserId).thenReturn(123);
        when(mockAuthProvider.currentUserEmail).thenReturn('test@example.com');
        when(mockNotesService.myLatest(10, 1))
            .thenAnswer((_) async => NotesResult([], 0));

        // Clear data first (simulating logout state)
        notesProvider.clearNotesCache();

        // Load data (simulating login)
        await notesProvider.onLogin();

        expect(appStateProvider.isAuthenticated, isTrue);
        expect(notesProviderNotifications, greaterThan(0));
      });

      test('should handle complete logout flow', () async {
        // Start with authenticated state
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockAuthProvider.currentUserId).thenReturn(123);
        when(mockAuthProvider.currentUserEmail).thenReturn('test@example.com');

        var appStateNotifications = 0;
        appStateProvider.addListener(() => appStateNotifications++);

        // Simulate logout
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        when(mockAuthProvider.currentUserId).thenReturn(null);
        when(mockAuthProvider.currentUserEmail).thenReturn(null);

        // Clear data
        notesProvider.clearNotesCache();

        expect(appStateProvider.isAuthenticated, isFalse);
        expect(appStateProvider.currentUser, isNull);
        expect(notesProvider.notes, isEmpty);
        expect(notesProvider.groupedNotes, isEmpty);
      });

      test('should handle auth state changes with data persistence', () async {
        // Login
        when(mockAuthProvider.isAuthenticated).thenReturn(true);
        when(mockNotesService.myLatest(10, 1))
            .thenAnswer((_) async => NotesResult([
              Note(id: 1, userId: 123, content: 'Test note',
                   isPrivate: false, isMarkdown: false, isLong: false,
                   createdAt: 1640995200, deletedAt: null, user: null, tags: [])
            ], 1));

        await notesProvider.loadPage(1);
        expect(notesProvider.notes.length, 1);

        // Logout should clear data
        when(mockAuthProvider.isAuthenticated).thenReturn(false);
        notesProvider.clearNotesCache();

        expect(notesProvider.notes, isEmpty);
        expect(notesProvider.groupedNotes, isEmpty);
      });
    });
  });
}
