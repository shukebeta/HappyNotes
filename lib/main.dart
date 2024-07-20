import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_notes/dependency_injection.dart' as di;
import 'package:happy_notes/screens/account/user_session.dart';
import 'package:happy_notes/screens/initial_page.dart';
import 'package:happy_notes/screens/main_menu.dart';
import 'package:happy_notes/screens/navigation/bottom_navigation.dart';
import 'package:provider/provider.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

import 'app_config.dart';
import 'models/note_model.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  di.init();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Run the app
  runApp(
    const HappyNotesApp(),
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
