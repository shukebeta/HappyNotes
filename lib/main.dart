import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_notes/dependency_injection.dart' as di;
import 'package:happy_notes/screens/account/user_session.dart';
import 'package:happy_notes/screens/initial_page.dart';
import 'package:happy_notes/screens/main_menu.dart';
import 'package:happy_notes/screens/navigation/bottom_navigation.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;


void main() async {
  di.init();
  await dotenv.load(fileName: '.env');
  runApp( const HappyNotesApp());
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const InitialPage(), // if already login then show main menu, otherwise show login page
      navigatorObservers: [UserSession.routeObserver],
    );
  }
}
