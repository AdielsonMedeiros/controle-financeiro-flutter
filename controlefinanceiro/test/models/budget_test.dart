import 'package:flutter_test/flutter_test.dart';
import 'package:controlefinanceiro/models/budget.dart';

void main() {
  group('Budget Model', () {
    test('deve criar orçamento com categorias', () {
      final budget = Budget(
        categories: {
          'Alimentação': 1000.0,
          'Transporte': 500.0,
          'Lazer': 300.0,
        },
      );

      expect(budget.categories.length, 3);
      expect(budget.categories['Alimentação'], 1000.0);
      expect(budget.categories['Transporte'], 500.0);
      expect(budget.categories['Lazer'], 300.0);
    });

    test('deve criar orçamento vazio', () {
      final budget = Budget(categories: {});
      expect(budget.categories.isEmpty, true);
    });

    test('fromFirestore deve converter dados corretamente', () {
      final data = {
        'Alimentação': 1500,
        'Transporte': 800.5,
        'Saúde': 1200,
      };

      final budget = Budget.fromFirestore(data);

      expect(budget.categories.length, 3);
      expect(budget.categories['Alimentação'], 1500.0);
      expect(budget.categories['Transporte'], 800.5);
      expect(budget.categories['Saúde'], 1200.0);
    });

    test('fromFirestore deve ignorar valores não numéricos', () {
      final data = {
        'Alimentação': 1000,
        'Invalido': 'texto',
        'Transporte': 500,
      };

      final budget = Budget.fromFirestore(data);

      expect(budget.categories.length, 2);
      expect(budget.categories.containsKey('Invalido'), false);
    });
  });
}
