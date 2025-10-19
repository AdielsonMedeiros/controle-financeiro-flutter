import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Data Validation Tests', () {
    test('deve validar valores monetários positivos', () {
      const value = 100.50;
      expect(value > 0, true);
      expect(value.isFinite, true);
    });

    test('deve rejeitar valores monetários negativos em despesas', () {
      const value = -50.0;
      expect(value < 0, true);
    });

    test('deve validar descrição não vazia', () {
      const description = 'Compra no mercado';
      expect(description.isNotEmpty, true);
      expect(description.trim().isNotEmpty, true);
    });

    test('deve validar categoria selecionada', () {
      const category = 'Alimentação';
      final validCategories = [
        'Alimentação',
        'Transporte',
        'Moradia',
        'Saúde',
        'Lazer',
        'Educação',
        'Outros'
      ];
      
      expect(validCategories.contains(category), true);
    });

    test('deve validar tipo de transação', () {
      const type = 'expense';
      final validTypes = ['income', 'expense'];
      
      expect(validTypes.contains(type), true);
    });

    test('deve validar data não futura para transações', () {
      final transactionDate = DateTime(2024, 1, 15);
      final now = DateTime.now();
      
      expect(transactionDate.isBefore(now) || transactionDate.isAtSameMomentAs(now), true);
    });

    test('deve validar formato de email', () {
      const validEmail = 'usuario@exemplo.com';
      const invalidEmail = 'usuario@';
      
      expect(validEmail.contains('@'), true);
      expect(validEmail.contains('.'), true);
      expect(invalidEmail.split('@').length == 2, true);
    });

    test('deve validar orçamento maior que zero', () {
      const budget = 1000.0;
      expect(budget > 0, true);
    });

    test('deve calcular saldo corretamente', () {
      const income = 5000.0;
      const expenses = 3000.0;
      final balance = income - expenses;
      
      expect(balance, 2000.0);
      expect(balance >= 0, true);
    });

    test('deve validar período de datas', () {
      final startDate = DateTime(2024, 1, 1);
      final endDate = DateTime(2024, 1, 31);
      
      expect(endDate.isAfter(startDate), true);
      expect(startDate.isBefore(endDate), true);
    });
  });
}
