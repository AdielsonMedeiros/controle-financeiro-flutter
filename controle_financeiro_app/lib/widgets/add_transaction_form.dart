// lib/widgets/add_transaction_form.dart

import 'package:controle_financeiro_app/models/financial_transaction.dart';
import 'package:controle_financeiro_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddTransactionForm extends StatefulWidget {
  final FinancialTransaction? transaction;
  // PARÂMETROS ADICIONADOS PARA RECEBER AS CATEGORIAS
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

  // REMOVIDO: As listas fixas de categorias foram removidas daqui

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
      
      // Garante que a categoria da transação a ser editada ainda exista na lista
      final currentCategories = t.type == 'expense' ? widget.allExpenseCategories : widget.allIncomeCategories;
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
    // Valida se uma categoria foi selecionada
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecione uma categoria.')),
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
            SnackBar(content: Text('Erro ao salvar: ${e.toString()}')),
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
    // MODIFICADO: Usa as listas recebidas pelo construtor
    final categories =
        isExpense ? widget.allExpenseCategories : widget.allIncomeCategories;

    final buttonColor = isExpense
        ? Theme.of(context).colorScheme.error.withOpacity(0.8)
        : Theme.of(context).colorScheme.secondary;

    final String title = _isEditMode ? 'Editar' : 'Adicionar';
    final String typeText = isExpense ? 'Gasto' : 'Receita';
    final String fullTitle = '$title $typeText';

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isEditMode)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  fullTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              )
            else
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Adicionar Gasto'),
                  Tab(text: 'Adicionar Receita')
                ],
                onTap: (_) => setState(() {
                  // Reseta a categoria selecionada ao trocar de aba
                  _selectedCategory = null;
                }),
              ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              validator: (v) =>
                  (v?.isEmpty ?? true) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              hint: const Text('Categoria'),
              items: categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (newValue) =>
                  setState(() => _selectedCategory = newValue),
              validator: (v) => v == null ? 'Selecione uma categoria' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Campo obrigatório';
                if (double.tryParse(v!) == null) return 'Valor inválido';
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: buttonColor),
                  child: Text(fullTitle,
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}