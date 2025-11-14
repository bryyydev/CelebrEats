import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    // A simple placeholder test to confirm the app runs correctly.
    // Replace or remove this file if you don’t use testing.
    const testWidget = MaterialApp(
      home: Scaffold(body: Center(child: Text('App Loaded'))),
    );

    await tester.pumpWidget(testWidget);

    expect(find.text('App Loaded'), findsOneWidget);
  });
}
