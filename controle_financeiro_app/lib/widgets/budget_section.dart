// lib/widgets/budget_section.dart

import 'package:controle_financeiro_app/models/budget.dart';
import 'package:controle_financeiro_app/models/financial_transaction.dart';
import 'package:controle_financeiro_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class BudgetSection extends StatefulWidget {
  final List<FinancialTransaction> expenses;
  final List<String> allExpenseCategories;

  const BudgetSection({
    super.key,
    required this.expenses,
    required this.allExpenseCategories,
  });

  @override
  State<BudgetSection> createState() => _BudgetSectionState();
}

class _BudgetSectionState extends State<BudgetSection> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;
  late Map<String, TextEditingController> _budgetControllers;
  bool _isLoading = false;
  late Map<String, FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(covariant BudgetSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
        oldWidget.allExpenseCategories, widget.allExpenseCategories)) {
      _disposeControllers();
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    _budgetControllers = {
      for (var cat in widget.allExpenseCategories) cat: TextEditingController(),
    };
    _focusNodes = {
      for (var cat in widget.allExpenseCategories) cat: FocusNode(),
    };
  }

  void _disposeControllers() {
    _budgetControllers.forEach((_, controller) => controller.dispose());
    _focusNodes.forEach((_, node) => node.dispose());
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  Future<void> _saveBudgets() async {
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    final newBudgets = <String, double>{};

    for (var category in widget.allExpenseCategories) {
      final controller = _budgetControllers[category];
      if (controller != null) {
        newBudgets[category] = double.tryParse(controller.text) ?? 0.0;
      }
    }

    try {
      await _firestoreService.saveBudgets(_userId!, newBudgets);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Orçamentos salvos com sucesso!'),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar orçamentos: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
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
              child: Text("Erro ao carregar orçamentos: ${snapshot.error}"));
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
            ...widget.allExpenseCategories.map((category) {
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
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saveBudgets,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(
                    'Salvar Orçamentos',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
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
    FocusNode focusNode,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverBudget
              ? Theme.of(context).colorScheme.error.withOpacity(0.3)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isOverBudget
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.category_rounded,
                      size: 18,
                      color: isOverBudget
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOverBudget
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: isOverBudget
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'R\$ ${spent.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isOverBudget
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'de R\$ ${budget.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor:
                  Theme.of(context).colorScheme.outline.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                isOverBudget
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            focusNode: focusNode,
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Definir Orçamento (R\$)',
              prefixIcon: const Icon(Icons.edit_rounded, size: 20),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
    );
  }
}
