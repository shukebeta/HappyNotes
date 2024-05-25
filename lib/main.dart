import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:happy_notes/dependency_injection.dart' as di;
import 'package:happy_notes/screens/initial_page.dart';
import 'package:happy_notes/screens/new_note.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform; // Import Platform for platform checks

void main() async {
  di.init();
  // AppLogger.initialize();
  await dotenv.load(fileName: '.env');
  runApp(const HappyNotesApp());
}

class HappyNotesApp extends StatefulWidget {
  const HappyNotesApp({super.key});

  @override
  State<HappyNotesApp> createState() => HappyNotesState();
}

class HappyNotesState extends State<HappyNotesApp> {
  QuickActions? quickActions;
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
        await navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => const NewNote(
              isPrivate: false,
            ),
          ),
        );
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
      home: const InitialPage(),
    );
  }
}
