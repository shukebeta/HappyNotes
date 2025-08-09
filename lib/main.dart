import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:happy_notes/dependency_injection.dart' as di;
import 'package:happy_notes/providers/auth_provider.dart';
import 'package:happy_notes/providers/notes_provider.dart';
import 'package:happy_notes/providers/app_state_provider.dart';
import 'package:happy_notes/screens/account/user_session.dart';
import 'package:happy_notes/screens/initial_page.dart';
import 'package:happy_notes/screens/main_menu.dart';
import 'package:happy_notes/screens/navigation/bottom_navigation.dart';
import 'package:happy_notes/services/seq_logger.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

import 'app_config.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  di.init();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize logging
  SeqLogger.initialize();

  // Disable browser context menu for Flutter web double selection fix
  if (kIsWeb) {
    BrowserContextMenu.disableContextMenu();
  }

  // Run the app with MultiProvider
  runApp(
    MultiProvider(
      providers: [
        // Create individual providers first
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (_) => NotesProvider(di.locator()),
        ),
        // Create AppStateProvider after individual providers
        ChangeNotifierProxyProvider2<AuthProvider, NotesProvider, AppStateProvider>(
          create: (context) => AppStateProvider(
            Provider.of<AuthProvider>(context, listen: false),
            Provider.of<NotesProvider>(context, listen: false),
          ),
          update: (context, authProvider, notesProvider, previous) =>
              previous ?? AppStateProvider(authProvider, notesProvider),
        ),
      ],
      child: const HappyNotesApp(),
    ),
  );
}

class HappyNotesApp extends StatefulWidget {
  const HappyNotesApp({super.key});

  @override
  State<HappyNotesApp> createState() => HappyNotesState();
}

class HappyNotesState extends State<HappyNotesApp> {
  QuickActions? quickActions;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<MainMenuState> mainMenuKey = GlobalKey<MainMenuState>();

  @override
  void initState() {
    super.initState();
    initializeQuickActions();
  }

  void initializeQuickActions() {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    quickActions = const QuickActions();
    quickActions!.setShortcutItems([
      const ShortcutItem(
        type: 'takeNote',
        localizedTitle: 'Take note',
        icon: 'pencil',
      ),
    ]);

    quickActions!.initialize((String shortcutType) async {
      if (shortcutType == 'takeNote') {
        if (mainMenuKey.currentState != null) {
          // MainMenu is already in the widget tree
          mainMenuKey.currentState?.switchToPage(indexNewNote); // Switch to 'New Note' page
        } else {
          // MainMenu is not in the widget tree, push it onto the stack
          await navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(
              builder: (context) => MainMenu(
                key: mainMenuKey,
                initialPageIndex: indexNewNote, // Start with 'New Note' page
              ),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      title: 'Happy Notes',
      theme: ThemeData(
        fontFamily: AppConfig.fontFamily,
        textTheme: Theme.of(context).textTheme.apply(fontFamily: AppConfig.fontFamily).copyWith(
              titleLarge: const TextStyle(fontSize: 19.0),
              titleMedium: const TextStyle(fontSize: 17.0),
              titleSmall: const TextStyle(fontSize: 15.0),
              bodyLarge: const TextStyle(fontSize: 16.0),
              bodyMedium: const TextStyle(fontSize: 14.0),
              bodySmall: const TextStyle(fontSize: 12.0),
            ),
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Show main menu if already logged in, otherwise show login page
      home: const InitialPage(),
      navigatorObservers: [UserSession.routeObserver],
    );
  }
}
