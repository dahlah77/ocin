import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocin_app/glass/adaptive_liquid_glass.dart';

void main() {
  testWidgets('Fallback preserves hit-testing for interactive child', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Center(
      child: SizedBox(width: 260, height: 80, child: AdaptiveLiquidGlass(
        backendOverride: GlassBackend.safeFallback,
        child: TextButton(
          key: const ValueKey('hit-target'),
          onPressed: () => taps++,
          child: const Text('Connect'),
        ),
      )),
    ))));
    await tester.tap(find.byKey(const ValueKey('hit-target')));
    await tester.pump();
    expect(taps, 1);
    expect(find.text('Connect'), findsOneWidget);
  });

  testWidgets('Repeated fallback cards do not create platform views', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Column(children:
      List.generate(6, (i) => SizedBox(height: 50, child: AdaptiveLiquidGlass(
        backendOverride: GlassBackend.safeFallback,
        child: Text('Device $i'),
      ))),
    ))));
    expect(find.byType(UiKitView), findsNothing);
    expect(find.byType(AppKitView), findsNothing);
  });
}
