import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controlefinanceiro/models/financial_transaction.dart';

void main() {
  group('FinancialTransaction Model', () {
    test('deve criar transação com valores corretos', () {
      final transaction = FinancialTransaction(
        id: '123',
        description: 'Salário',
        category: 'Trabalho',
        amount: 5000.0,
        type: 'income',
        createdAt: DateTime(2024, 1, 15),
      );

      expect(transaction.id, '123');
      expect(transaction.description, 'Salário');
      expect(transaction.category, 'Trabalho');
      expect(transaction.amount, 5000.0);
      expect(transaction.type, 'income');
      expect(transaction.createdAt, DateTime(2024, 1, 15));
    });

    test('deve aceitar valores decimais no amount', () {
      final transaction = FinancialTransaction(
        id: '456',
        description: 'Café',
        category: 'Alimentação',
        amount: 12.50,
        type: 'expense',
        createdAt: DateTime.now(),
      );

      expect(transaction.amount, 12.50);
      expect(transaction.type, 'expense');
    });

    test('deve aceitar amount zero', () {
      final transaction = FinancialTransaction(
        id: '789',
        description: 'Teste',
        category: 'Outros',
        amount: 0.0,
        type: 'expense',
        createdAt: DateTime.now(),
      );

      expect(transaction.amount, 0.0);
    });
  });
}
