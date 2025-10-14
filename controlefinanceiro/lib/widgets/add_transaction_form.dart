// lib/widgets/add_transaction_form.dart

import 'package:controlefinanceiro/models/financial_transaction.dart';
import 'package:controlefinanceiro/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddTransactionForm extends StatefulWidget {
  final FinancialTransaction? transaction;
  final List<String> allExpenseCategories;
  final List<String> allIncomeCategories;

  const AddTransactionForm({
    super.key,
    this.transaction,
    required this.allExpenseCategories,
    required this.allIncomeCategories,
  });

  @override
  State<AddTransactionForm> createState() => _AddTransactionFormState();
}

class _AddTransactionFormState extends State<AddTransactionForm>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  late bool _isEditMode;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.transaction != null;
    _tabController = TabController(
      initialIndex: _isEditMode && widget.transaction!.type == 'income' ? 1 : 0,
      length: 2,
      vsync: this,
    );

    if (_isEditMode) {
      final t = widget.transaction!;
      _descriptionController.text = t.description;
      _amountController.text = t.amount.toString();
      final currentCategories = t.type == 'expense'
          ? widget.allExpenseCategories
          : widget.allIncomeCategories;
      if (currentCategories.contains(t.category)) {
        _selectedCategory = t.category;
      }
    }

    _tabController.addListener(() {
      if (_tabController.indexIsChanging && !_isEditMode) {
        _formKey.currentState?.reset();
        _descriptionController.clear();
        _amountController.clear();
        setState(() => _selectedCategory = null);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, selecione uma categoria.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final firestoreService = FirestoreService();
      final user = FirebaseAuth.instance.currentUser;
      final isExpense = _tabController.index == 0;

      final transactionData = {
        'id': _isEditMode ? widget.transaction!.id : null,
        'description': _descriptionController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'category': _selectedCategory,
        'type': isExpense ? 'expense' : 'income',
      };

      try {
        if (_isEditMode) {
          await firestoreService.updateTransaction(user!.uid, transactionData);
        } else {
          await firestoreService.addTransaction(user!.uid, transactionData);
        }

        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao salvar: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _tabController.index == 0;
    final categories =
        isExpense ? widget.allExpenseCategories : widget.allIncomeCategories;
    final buttonColor = isExpense
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.secondary;

    final String title = _isEditMode ? 'Editar' : 'Adicionar';
    final String typeText = isExpense ? 'Gasto' : 'Receita';
    final String fullTitle = '$title $typeText';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (_isEditMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: buttonColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isExpense
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: buttonColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      fullTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  tabs: const [
                    Tab(text: 'Gasto'),
                    Tab(text: 'Receita'),
                  ],
                  onTap: (_) => setState(() {
                    _selectedCategory = null;
                  }),
                ),
              ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                prefixIcon: const Icon(Icons.description_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              validator: (v) => (v?.isEmpty ?? true) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              hint: const Text('Selecione a categoria'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.category_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              items: categories.map((String category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (newValue) => setState(() => _selectedCategory = newValue),
              validator: (v) => v == null ? 'Selecione uma categoria' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Valor (R\$)',
                prefixIcon: const Icon(Icons.attach_money_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Campo obrigatório';
                if (double.tryParse(v!) == null) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: buttonColor,
                  strokeWidth: 3,
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: buttonColor.withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isEditMode ? Icons.check_circle_rounded : Icons.add_circle_rounded,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        fullTitle,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
