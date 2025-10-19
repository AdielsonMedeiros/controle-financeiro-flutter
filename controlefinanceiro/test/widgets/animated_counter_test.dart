import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:controlefinanceiro/widgets/animated_counter.dart';

void main() {
  group('AnimatedCounter Widget', () {
    testWidgets('deve renderizar valor inicial', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 1000.0,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedCounter), findsOneWidget);
    });

    testWidgets('deve aceitar valores negativos', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: -500.0,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedCounter), findsOneWidget);
    });

    testWidgets('deve aceitar valor zero', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCounter(
              value: 0.0,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedCounter), findsOneWidget);
    });
  });
}
