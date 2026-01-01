import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:port21/main.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const Port21App());

    // Verify that our Login Screen appears
    expect(find.text('Connect to Server'), findsOneWidget);
    expect(find.text('Host Address'), findsOneWidget);
    expect(find.byIcon(Icons.login), findsOneWidget);
  });
}
