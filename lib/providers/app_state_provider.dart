import 'package:flutter/foundation.dart';
import 'package:happy_notes/providers/auth_provider.dart';
import 'package:happy_notes/providers/notes_provider.dart';
import 'package:happy_notes/providers/search_provider.dart';
import 'package:happy_notes/providers/tag_provider.dart';
import 'package:happy_notes/providers/memories_provider.dart';
import 'package:happy_notes/providers/trash_provider.dart';
import 'package:happy_notes/providers/discovery_provider.dart';
import 'package:happy_notes/providers/provider_base.dart';

/// Central application state coordinator
/// Orchestrates all provider states and handles auth state propagation
/// Following new_words AppStateProvider pattern for proven architecture
class AppStateProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  final NotesProvider _notesProvider;
  final SearchProvider _searchProvider;
  final TagProvider _tagProvider;
  final MemoriesProvider _memoriesProvider;
  final TrashProvider _trashProvider;
  final DiscoveryProvider _discoveryProvider;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AppStateProvider(
    this._authProvider, 
    this._notesProvider,
    this._searchProvider,
    this._tagProvider,
    this._memoriesProvider,
    this._trashProvider,
    this._discoveryProvider,
  ) {
    debugPrint('AppStateProvider: Constructor called - setting up listeners');
    _initializeProvider();
  }

  /// Initialize the app state provider
  void _initializeProvider() {
    // Listen to auth state changes
    _authProvider.addListener(_onAuthStateChanged);
    _isInitialized = true;
    notifyListeners();
  }

  /// Handle authentication state changes
  /// Coordinates state across all providers when auth changes
  void _onAuthStateChanged() async {
    final isAuthenticated = _authProvider.isAuthenticated;
    debugPrint('AppStateProvider: Auth state changed - isAuthenticated: $isAuthenticated');
    
    // Always clear data first to prevent stale data
    await _clearAllProviderData();
    
    // Notify listeners immediately after clearing to update UI
    notifyListeners();
    
    // Then handle the auth state change
    await _notifyProvidersOfAuthChange(isAuthenticated);
    
    // Final notification
    notifyListeners();
  }


  /// Notify all auth-aware providers of authentication state changes
  Future<void> _notifyProvidersOfAuthChange(bool isAuthenticated) async {
    final List<Future<void>> futures = [];
    
    // Collect all auth-aware providers
    final List<AuthAwareProvider> providers = [
      _notesProvider,
      _searchProvider,
      _tagProvider,
      _memoriesProvider,
      _trashProvider,
      _discoveryProvider,
    ];
    
    // Notify all providers of auth state change
    for (final provider in providers) {
      futures.add(provider.onAuthStateChanged(isAuthenticated));
    }
    
    // Wait for all providers to complete their auth state handling
    await Future.wait(futures);
  }

  /// Clear data from all providers
  Future<void> _clearAllProviderData() async {
    final List<AuthAwareProvider> providers = [
      _notesProvider,
      _searchProvider,
      _tagProvider,
      _memoriesProvider,
      _trashProvider,
      _discoveryProvider,
    ];
    
    for (final provider in providers) {
      provider.clearAllData();
    }
  }

  /// Manual refresh of all provider data
  /// Useful for pull-to-refresh or manual sync
  Future<void> refreshAllData() async {
    if (!_authProvider.isAuthenticated) return;
    
    try {
      // Refresh all provider data
      await _notesProvider.refreshNotes();
      await _searchProvider.refreshSearch();
      await _tagProvider.loadTagCloud(forceRefresh: true);
      await _memoriesProvider.refreshMemories();
      await _trashProvider.refresh();
      await _discoveryProvider.refresh();
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error refreshing app data: $e');
      }
    }
  }

  /// Get the current authentication state
  bool get isAuthenticated => _authProvider.isAuthenticated;

  /// Get the current user information
  Map<String, dynamic>? get currentUser {
    if (!_authProvider.isAuthenticated) return null;
    return {
      'id': _authProvider.currentUserId,
      'email': _authProvider.currentUserEmail,
    };
  }

  /// Check if any provider is currently loading
  bool get isLoading => _notesProvider.isLoadingList || _notesProvider.isLoadingAdd;

  /// Get any current errors from providers
  List<String> get errors {
    final List<String> errorList = [];
    
    if (_notesProvider.listError != null) {
      errorList.add(_notesProvider.listError!);
    }
    if (_notesProvider.addError != null) {
      errorList.add(_notesProvider.addError!);
    }
    
    return errorList;
  }

  /// Clear all errors from providers
  void clearAllErrors() {
    // Clear errors from all providers
    // Note: Individual providers should handle their own error clearing
    // This is a convenience method for global error management
    notifyListeners();
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthStateChanged);
    super.dispose();
  }
}