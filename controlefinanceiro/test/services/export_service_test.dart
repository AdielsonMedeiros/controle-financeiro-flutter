import 'package:flutter_test/flutter_test.dart';
import 'package:controlefinanceiro/models/financial_transaction.dart';

void main() {
  group('Export Service Logic', () {
    test('deve calcular totais corretamente', () {
      final transactions = [
        FinancialTransaction(
          id: '1',
          description: 'Salário',
          category: 'Trabalho',
          amount: 5000.0,
          type: 'income',
          createdAt: DateTime(2024, 1, 15),
        ),
        FinancialTransaction(
          id: '2',
          description: 'Aluguel',
          category: 'Moradia',
          amount: 1500.0,
          type: 'expense',
          createdAt: DateTime(2024, 1, 20),
        ),
        FinancialTransaction(
          id: '3',
          description: 'Freelance',
          category: 'Trabalho',
          amount: 800.0,
          type: 'income',
          createdAt: DateTime(2024, 1, 25),
        ),
      ];

      final totalIncome = transactions
          .where((t) => t.type == 'income')
          .fold(0.0, (sum, t) => sum + t.amount);

      final totalExpenses = transactions
          .where((t) => t.type == 'expense')
          .fold(0.0, (sum, t) => sum + t.amount);

      final balance = totalIncome - totalExpenses;

      expect(totalIncome, 5800.0);
      expect(totalExpenses, 1500.0);
      expect(balance, 4300.0);
    });

    test('deve filtrar transações por período', () {
      final transactions = [
        FinancialTransaction(
          id: '1',
          description: 'Janeiro',
          category: 'Teste',
          amount: 100.0,
          type: 'expense',
          createdAt: DateTime(2024, 1, 15),
        ),
        FinancialTransaction(
          id: '2',
          description: 'Fevereiro',
          category: 'Teste',
          amount: 200.0,
          type: 'expense',
          createdAt: DateTime(2024, 2, 15),
        ),
        FinancialTransaction(
          id: '3',
          description: 'Março',
          category: 'Teste',
          amount: 300.0,
          type: 'expense',
          createdAt: DateTime(2024, 3, 15),
        ),
      ];

      final startDate = DateTime(2024, 2, 1);
      final endDate = DateTime(2024, 2, 28);

      final filtered = transactions.where((t) =>
          t.createdAt.isAfter(startDate.subtract(const Duration(days: 1))) &&
          t.createdAt.isBefore(endDate.add(const Duration(days: 1)))).toList();

      expect(filtered.length, 1);
      expect(filtered.first.description, 'Fevereiro');
    });

    test('deve lidar com lista vazia', () {
      final List<FinancialTransaction> transactions = [];

      final totalIncome = transactions
          .where((t) => t.type == 'income')
          .fold(0.0, (sum, t) => sum + t.amount);

      expect(totalIncome, 0.0);
      expect(transactions.isEmpty, true);
    });
  });
}
