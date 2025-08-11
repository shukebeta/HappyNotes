import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_notes/dependency_injection.dart' as di;
import 'package:happy_notes/providers/auth_provider.dart';
import 'package:happy_notes/providers/notes_provider.dart';
import 'package:happy_notes/providers/search_provider.dart';
import 'package:happy_notes/providers/tag_notes_provider.dart';
import 'package:happy_notes/providers/memories_provider.dart';
import 'package:happy_notes/providers/trash_provider.dart';
import 'package:happy_notes/providers/discovery_provider.dart';
import 'package:happy_notes/providers/app_state_provider.dart';
import 'package:happy_notes/apis/notes_api.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'mock_notes_api.dart';
import 'mock_dio.dart';
import 'mock_notes_service.dart';
void registerTestMocks() {
  final sl = GetIt.instance;
  if (sl.isRegistered<NotesApi>()) {
    sl.unregister<NotesApi>();
  }
  sl.registerLazySingleton<NotesApi>(() => MockNotesApi());
  if (sl.isRegistered<Dio>()) {
    sl.unregister<Dio>();
  }
  sl.registerLazySingleton<Dio>(() => MockDio());
}

/// Initializes DI and wraps [child] in the full provider tree as in main.dart.
/// Use in widget tests to ensure all dependencies are registered.
Widget buildWidgetTestHarness(Widget child) {
  di.init();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => NotesProvider(di.locator())),
      ChangeNotifierProvider(create: (_) => SearchProvider(di.locator(), di.locator())),
      ChangeNotifierProvider(create: (_) => TagNotesProvider(di.locator(), di.locator())),
      ChangeNotifierProvider(create: (_) => MemoriesProvider(di.locator())),
      ChangeNotifierProvider(create: (_) => TrashProvider(di.locator())),
      ChangeNotifierProvider(create: (_) => DiscoveryProvider(di.locator())),
      ChangeNotifierProvider<AppStateProvider>(
        lazy: false,
        create: (context) => AppStateProvider(
          Provider.of<AuthProvider>(context, listen: false),
          Provider.of<NotesProvider>(context, listen: false),
          Provider.of<SearchProvider>(context, listen: false),
          Provider.of<TagNotesProvider>(context, listen: false),
          Provider.of<MemoriesProvider>(context, listen: false),
          Provider.of<TrashProvider>(context, listen: false),
          Provider.of<DiscoveryProvider>(context, listen: false),
        ),
      ),
    ],
    child: MaterialApp(home: child),
  );
}