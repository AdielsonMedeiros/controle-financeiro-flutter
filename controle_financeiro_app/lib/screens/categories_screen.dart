// lib/screens/categories_screen.dart

import 'package:controle_financeiro_app/models/categories.dart';
import 'package:controle_financeiro_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  void _showAddCategoryDialog(
      BuildContext context, Categories currentCategories, String type) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Nova Categoria de ${type == 'expense' ? 'Gasto' : 'Receita'}'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Nome da Categoria'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira um nome.';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              child: const Text('Adicionar'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newCategory = controller.text.trim();
                  if (type == 'expense') {
                    currentCategories.expenseCategories.add(newCategory);
                  } else {
                    currentCategories.incomeCategories.add(newCategory);
                  }
                  _firestoreService.saveCategories(_user!.uid, currentCategories);
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(Categories currentCategories, String type, String category) {
     if (type == 'expense') {
        currentCategories.expenseCategories.remove(category);
      } else {
        currentCategories.incomeCategories.remove(category);
      }
      _firestoreService.saveCategories(_user!.uid, currentCategories);
  }


  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("Usuário não encontrado.")));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciar Categorias'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Despesas'),
              Tab(text: 'Receitas'),
            ],
          ),
        ),
        body: StreamBuilder<Categories>(
          stream: _firestoreService.getCategoriesStream(_user!.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Erro: ${snapshot.error}"));
            }

            final categories = snapshot.data ??
                Categories(expenseCategories: [], incomeCategories: []);

            return TabBarView(
              children: [
                _buildCategoryList(context, 'expense', categories),
                _buildCategoryList(context, 'income', categories),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryList(
      BuildContext context, String type, Categories categories) {
    final list =
        type == 'expense' ? categories.expenseCategories : categories.incomeCategories;
    
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Nenhuma categoria personalizada.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Primeira'),
              onPressed: () => _showAddCategoryDialog(context, categories, type),
            )
          ],
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        itemCount: list.length,
        itemBuilder: (ctx, index) {
          final category = list[index];
          return ListTile(
            title: Text(category),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteCategory(categories, type, category),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, categories, type),
        child: const Icon(Icons.add),
      ),
    );
  }
}