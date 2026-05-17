import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MoodTrackerApp());
}

class MoodTrackerApp extends StatelessWidget {
  const MoodTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mood Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFFC93C),
        scaffoldBackgroundColor: const Color(0xFFFFF7E6),
      ),
      home: const HomeScreen(),
    );
  }
}
