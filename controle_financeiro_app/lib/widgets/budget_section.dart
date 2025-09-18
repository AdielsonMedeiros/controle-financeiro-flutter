// lib/widgets/budget_section.dart

import 'package:controle_financeiro_app/main.dart';
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

  // As categorias de despesa que seu app usa
  final List<String> _expenseCategories = const ['Alimentação', 'Transporte', 'Lazer', 'Moradia', 'Saúde', 'Outros'];

  // --- CORREÇÃO DO ERRO 2: Controllers são criados uma única vez aqui ---
  @override
  void initState() {
    super.initState();
    _budgetControllers = {
      for (var cat in _expenseCategories) cat: TextEditingController(),
    };
  }

  @override
  void dispose() {
    _budgetControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _saveBudgets() async {
    // Esconde o teclado para não atrapalhar a SnackBar
    FocusScope.of(context).unfocus();
    
    setState(() => _isLoading = true);
    final newBudgets = <String, double>{};
    _budgetControllers.forEach((category, controller) {
      newBudgets[category] = double.tryParse(controller.text) ?? 0.0;
    });

    try {
      await _firestoreService.saveBudgets(_userId!, newBudgets);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamentos salvos com sucesso!'), backgroundColor: AppColors.sucesso),
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
        // --- CORREÇÃO DO ERRO 1: Verificação correta do estado da conexão ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Erro ao carregar orçamentos: ${snapshot.error}"));
        }
        // Se a stream termina sem dados (documento não existe), cria um orçamento vazio
        final budget = snapshot.data ?? Budget(categories: {});

        // --- CORREÇÃO DO ERRO 3: Sincroniza o texto dos controllers existentes ---
        // Isso atualiza os campos com os dados do banco sem recriar os controllers
        budget.categories.forEach((category, value) {
          if (_budgetControllers.containsKey(category)) {
            final controller = _budgetControllers[category]!;
            final formattedValue = value.toStringAsFixed(2);
            // Só atualiza se o texto for diferente para não atrapalhar a digitação
            if (controller.text != formattedValue) {
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
              final progress = (budgetAmount > 0) ? (spentAmount / budgetAmount) : 0.0;
              final isOverBudget = progress > 1.0;

              return _buildBudgetItem(
                context,
                category,
                spentAmount,
                budgetAmount,
                progress,
                isOverBudget,
                _budgetControllers[category]!,
              );
            }).toList(),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveBudgets,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.sucesso),
                  child: const Text('Salvar Orçamentos', style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetItem(
    BuildContext context, String category, double spent, double budget, double progress,
    bool isOverBudget, TextEditingController controller,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borda),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'R\$ ${spent.toStringAsFixed(2)} / R\$ ${budget.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isOverBudget ? AppColors.erro : AppColors.textoSuave,
                    fontWeight: isOverBudget ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.isFinite ? progress : 0.0, // Garante que o valor é finito
                minHeight: 12,
                backgroundColor: AppColors.borda,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isOverBudget ? AppColors.erro : AppColors.primaria,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Definir Orçamento (R\$)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
    );
  }
}