import 'package:ff_bloc_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('loads, adds, clears, reports an error, and reloads',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Header 0, id = 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('Index = 1, id = 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(find.text('Empty'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.error));
    await tester.pumpAndSettle();
    expect(find.textContaining('Test error'), findsOneWidget);

    await tester.tap(find.text('Reload'));
    await tester.pumpAndSettle();
    expect(find.text('Header 0, id = 1'), findsOneWidget);
  });
}
