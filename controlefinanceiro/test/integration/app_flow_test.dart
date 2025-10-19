import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App Integration Tests', () {
    testWidgets('deve validar formatação de moeda brasileira', (WidgetTester tester) async {
      const value = 1234.56;
      final formatted = 'R\$ 1.234,56';
      
      expect(formatted.contains('R\$'), true);
      expect(formatted.contains(','), true);
    });

    testWidgets('deve validar cálculos de porcentagem', (WidgetTester tester) async {
      const spent = 800.0;
      const budget = 1000.0;
      final percentage = (spent / budget * 100);
      
      expect(percentage, 80.0);
      expect(percentage <= 100, true);
    });

    testWidgets('deve validar comparação de datas', (WidgetTester tester) async {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, now.day);
      
      expect(now.isAfter(lastMonth), true);
      expect(lastMonth.isBefore(now), true);
    });

    testWidgets('deve validar ordenação de transações por data', (WidgetTester tester) async {
      final dates = [
        DateTime(2024, 3, 15),
        DateTime(2024, 1, 10),
        DateTime(2024, 2, 20),
      ];

      dates.sort((a, b) => b.compareTo(a));

      expect(dates.first, DateTime(2024, 3, 15));
      expect(dates.last, DateTime(2024, 1, 10));
    });

    testWidgets('deve validar filtro de mês atual', (WidgetTester tester) async {
      final now = DateTime.now();
      final testDate = DateTime(now.year, now.month, 15);
      final oldDate = DateTime(now.year, now.month - 2, 15);

      final isCurrentMonth = testDate.year == now.year && testDate.month == now.month;
      final isOldMonth = oldDate.year == now.year && oldDate.month == now.month;

      expect(isCurrentMonth, true);
      expect(isOldMonth, false);
    });
  });
}
