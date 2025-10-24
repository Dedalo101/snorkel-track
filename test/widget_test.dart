// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:snorkel_track/main.dart';

void main() {
  testWidgets('SnorkelTrack app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SnorkelTrackApp());

    // Verify that the app title is present.
    expect(find.text('🏊‍♂️ SnorkelTrack'), findsOneWidget);

    // Verify that the bottom navigation has the expected tabs.
    expect(find.text('Mark Spot'), findsOneWidget);
    expect(find.text('Navigate'), findsOneWidget);
    expect(find.text('Spots'), findsOneWidget);
  });
}
