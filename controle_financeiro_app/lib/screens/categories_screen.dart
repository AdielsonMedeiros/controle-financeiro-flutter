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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.add_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Nova Categoria\nde ${type == 'expense' ? 'Gasto' : 'Receita'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nome da Categoria',
                prefixIcon: const Icon(Icons.category_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, insira um nome.';
                }
                return null;
              },
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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

  void _deleteCategory(
      Categories currentCategories, String type, String category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir a categoria "$category"?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Excluir'),
            onPressed: () {
              if (type == 'expense') {
                currentCategories.expenseCategories.remove(category);
              } else {
                currentCategories.incomeCategories.remove(category);
              }
              _firestoreService.saveCategories(_user!.uid, currentCategories);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
          body: Center(child: Text("Usuário não encontrado.")));
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gerenciar Categorias'),
          centerTitle: false,
          bottom: TabBar(
            indicator: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: const [
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
    final list = type == 'expense'
        ? categories.expenseCategories
        : categories.incomeCategories;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.category_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Nenhuma categoria personalizada.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_rounded),
              label: const Text('Adicionar Primeira'),
              onPressed: () => _showAddCategoryDialog(context, categories, type),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (ctx, index) {
          final category = list[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.category_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              title: Text(
                category,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => _deleteCategory(categories, type, category),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context, categories, type),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Categoria'),
        elevation: 4,
      ),
    );
  }
}
