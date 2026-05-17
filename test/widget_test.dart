import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App boots and shows the Mood Tracker title',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MoodTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Mood Tracker'), findsOneWidget);
    expect(find.text('How are you feeling?'), findsOneWidget);
  });
}
