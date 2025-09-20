

import 'package:controle_financeiro_app/main.dart';
import 'package:controle_financeiro_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddTransactionForm extends StatefulWidget {
  const AddTransactionForm({super.key});

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

  
  final List<String> _expenseCategories = [
    'Alimentação', 'Transporte', 'Lazer', 'Moradia', 'Saúde', 'Outros'
  ];
  final List<String> _incomeCategories = [
    'Salário', 'Investimentos', 'Freelance', 'Presente', 'Outros'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _formKey.currentState?.reset();
        _descriptionController.clear();
        _amountController.clear();
        setState(() {
          _selectedCategory = null;
        });
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
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final firestoreService = FirestoreService();
      final user = FirebaseAuth.instance.currentUser;
      final isExpense = _tabController.index == 0;

      final transactionData = {
        'description': _descriptionController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'category': _selectedCategory,
        'type': isExpense ? 'expense' : 'income',
      };

      try {
        await firestoreService.addTransaction(user!.uid, transactionData);
        Navigator.of(context).pop(); 
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: ${e.toString()}')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final isExpense = _tabController.index == 0;
    final categories = isExpense ? _expenseCategories : _incomeCategories;
    final buttonColor = isExpense ? AppColors.erro : AppColors.sucesso;

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
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Adicionar Gasto'),
                Tab(text: 'Adicionar Receita'),
              ],
              onTap: (_) => setState(() {}), 
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição'),
              validator: (value) => (value?.isEmpty ?? true) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            
            AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (context, child) {
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  hint: const Text('Categoria'),
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() => _selectedCategory = newValue);
                  },
                  validator: (value) => value == null ? 'Selecione uma categoria' : null,
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Valor (R\$)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Campo obrigatório';
                if (double.tryParse(value!) == null) return 'Valor inválido';
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
                  child: Text(isExpense ? 'Adicionar Gasto' : 'Adicionar Receita', style: const TextStyle(color: Colors.white)),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}