

import 'package:controle_financeiro_app/models/budget.dart';
import 'package:controle_financeiro_app/models/financial_transaction.dart';
import 'package:controle_financeiro_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class BudgetSection extends StatefulWidget {
  final List<FinancialTransaction> expenses;

  const BudgetSection({super.key, required this.expenses});

  @override
  State<BudgetSection> createState() => _BudgetSectionState();
}

class _BudgetSectionState extends State<BudgetSection> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  late Map<String, TextEditingController> _budgetControllers;
  bool _isLoading = false;

  late Map<String, FocusNode> _focusNodes;

  final List<String> _expenseCategories = const [
    'Alimentação',
    'Transporte',
    'Lazer',
    'Moradia',
    'Saúde',
    'Outros'
  ];

  @override
  void initState() {
    super.initState();

    _budgetControllers = {
      for (var cat in _expenseCategories) cat: TextEditingController(),
    };

    _focusNodes = {
      for (var cat in _expenseCategories) cat: FocusNode(),
    };
  }

  @override
  void dispose() {
    _budgetControllers.forEach((_, controller) => controller.dispose());

    _focusNodes.forEach((_, node) => node.dispose());
    super.dispose();
  }

  Future<void> _saveBudgets() async {
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    final newBudgets = <String, double>{};
    _budgetControllers.forEach((category, controller) {
      newBudgets[category] = double.tryParse(controller.text) ?? 0.0;
    });

    try {
      await _firestoreService.saveBudgets(_userId!, newBudgets);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Orçamentos salvos com sucesso!'),
            backgroundColor: Theme.of(context).colorScheme.secondary),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar orçamentos: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) return const SizedBox.shrink();

    return StreamBuilder<Budget>(
      stream: _firestoreService.getBudgetsStream(_userId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _budgetControllers.values.every((c) => c.text.isEmpty)) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child:
                  Text("Erro ao carregar orçamentos: ${snapshot.error}"));
        }

        final budget = snapshot.data ?? Budget(categories: {});

        budget.categories.forEach((category, value) {
          if (_budgetControllers.containsKey(category)) {
            final controller = _budgetControllers[category]!;
            final formattedValue = value > 0 ? value.toStringAsFixed(2) : '';
            final focusNode = _focusNodes[category]!;

            if (!focusNode.hasFocus && controller.text != formattedValue) {
              controller.text = formattedValue;
            }
          }
        });

        final spentByCategory = <String, double>{};
        for (var expense in widget.expenses) {
          spentByCategory.update(
            expense.category,
            (value) => value + expense.amount,
            ifAbsent: () => expense.amount,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._expenseCategories.map((category) {
              final budgetAmount = budget.categories[category] ?? 0.0;
              final spentAmount = spentByCategory[category] ?? 0.0;
              final progress =
                  (budgetAmount > 0) ? (spentAmount / budgetAmount) : 0.0;
              final isOverBudget = progress > 1.0;

              return _buildBudgetItem(
                context,
                category,
                spentAmount,
                budgetAmount,
                progress,
                isOverBudget,
                _budgetControllers[category]!,
                _focusNodes[category]!,
              );
            }),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveBudgets,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary),
                  child: const Text('Salvar Orçamentos',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetItem(
      BuildContext context,
      String category,
      double spent,
      double budget,
      double progress,
      bool isOverBudget,
      TextEditingController controller,
      FocusNode focusNode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'R\$ ${spent.toStringAsFixed(2)} / R\$ ${budget.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isOverBudget
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight:
                        isOverBudget ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 12,
                backgroundColor: Theme.of(context).colorScheme.outline,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              focusNode: focusNode,
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Definir Orçamento (R\$)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
    );
  }
}