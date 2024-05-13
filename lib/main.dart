import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'screens/login.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  runApp(const HappyNotesApp());
}

class HappyNotesApp extends StatelessWidget {
  const HappyNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Happy Notes',
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Login(title: 'Login'),
    );
  }
}

