import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocin_app/widgets/status_badge.dart';

void main() {
  testWidgets('status badge exposes a readable label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatusBadge(label: 'Bridge aktif', positive: true)),
    ));
    expect(find.text('Bridge aktif'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
  });
}
