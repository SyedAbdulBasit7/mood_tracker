import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/main.dart';

void main() {
  testWidgets('App boots and shows the Mood Tracker title',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MoodTrackerApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Mood Tracker'), findsOneWidget);
  });
}
