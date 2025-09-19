// lib/screens/home_screen.dart

import 'package:controle_financeiro_app/main.dart';
import 'package:controle_financeiro_app/models/financial_transaction.dart';
import 'package:controle_financeiro_app/services/firestore_service.dart';
import 'package:controle_financeiro_app/widgets/add_transaction_form.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("Usuário não encontrado.")));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão Geral'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: _firestoreService.getTransactionsStream(_user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final transactions = snapshot.data!;
          return _buildDashboard(transactions);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => const AddTransactionForm(),
          );
        },
        backgroundColor: AppColors.primaria,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDashboard(List<FinancialTransaction> transactions) {
    double totalIncome = transactions.where((t) => t.type == 'income').fold(0, (sum, item) => sum + item.amount);
    double totalExpenses = transactions.where((t) => t.type == 'expense').fold(0, (sum, item) => sum + item.amount);
    double balance = totalIncome - totalExpenses;
    final expenseTransactions = transactions.where((t) => t.type == 'expense').toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      children: [
        const SizedBox(height: 16),
        _buildUserInfoHeader(),
        const SizedBox(height: 24),
        _buildSummaryCards(totalIncome, totalExpenses, balance),
        const SizedBox(height: 24),
        Text(
          'Análise de Despesas',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildExpenseChart(expenseTransactions, totalExpenses), // Passando o total de despesas
        const SizedBox(height: 24),
        Text(
          'Histórico de Transações',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildTransactionList(transactions),
      ],
    );
  }
  
  Widget _buildExpenseChart(List<FinancialTransaction> expenseTransactions, double totalExpenses) {
    if (expenseTransactions.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        child: const Text('Nenhuma despesa para analisar.', style: TextStyle(color: AppColors.textoSuave)),
      );
    }
    final Map<String, double> categoryTotals = {};
    for (var transaction in expenseTransactions) {
      categoryTotals.update(transaction.category, (value) => value + transaction.amount, ifAbsent: () => transaction.amount);
    }
    
    final List<Color> chartColors = [
      AppColors.erro.withOpacity(0.9), AppColors.primaria.withOpacity(0.8), Colors.amber.shade400,
      Colors.cyan.shade400, Colors.purple.shade400, Colors.orange.shade400
    ];

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 80,
              sections: List.generate(categoryTotals.length, (i) {
                final entry = categoryTotals.entries.elementAt(i);
                final percentage = (entry.value / totalExpenses * 100);
                return PieChartSectionData(
                  color: chartColors[i % chartColors.length],
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 40,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Total Gasto", style: TextStyle(color: AppColors.textoSuave, fontSize: 16)),
              Text(
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(totalExpenses),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          )
        ],
      ),
    );
  }
  
  Widget _buildUserInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.container,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borda),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage(
              _user?.photoURL ??
                  'https://ui-avatars.com/api/?name=${_user?.email ?? 'A'}&background=4F46E5&color=fff',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bem-vindo de volta!', style: TextStyle(color: AppColors.textoSuave)),
                Text(
                  _user?.email ?? 'Usuário',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.texto),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
     return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: AppColors.textoSuave),
          SizedBox(height: 16),
          Text("Nenhuma transação encontrada.", style: TextStyle(fontSize: 18, color: AppColors.textoSuave)),
          SizedBox(height: 8),
          Text("Clique no botão '+' para adicionar.", style: TextStyle(color: AppColors.textoSuave)),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expenses, double balance) {
    return GridView(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(title: 'Receitas', amount: income, color: AppColors.sucesso),
        _SummaryCard(title: 'Despesas', amount: expenses, color: AppColors.erro),
        _SummaryCard(title: 'Saldo', amount: balance, color: balance >= 0 ? AppColors.sucesso : AppColors.erro),
      ],
    );
  }

  Widget _buildTransactionList(List<FinancialTransaction> transactions) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final isIncome = transaction.type == 'income';
          final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

          return Dismissible(
            key: Key(transaction.id),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _firestoreService.deleteTransaction(_user!.uid, transaction);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${transaction.description} removido(a).')),
              );
            },
            background: Container(
              color: AppColors.erro,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              title: Text(transaction.description),
              subtitle: Text(transaction.category),
              trailing: Text(
                '${isIncome ? '+' : '-'} ${formatter.format(transaction.amount)}',
                style: TextStyle(
                  color: isIncome ? AppColors.sucesso : AppColors.erro,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(height: 1),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.container,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borda),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, color: AppColors.textoSuave)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatter.format(amount),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}