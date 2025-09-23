// lib/screens/home_screen.dart

import 'package:controle_financeiro_app/models/categories.dart';
import 'package:controle_financeiro_app/models/financial_transaction.dart';
import 'package:controle_financeiro_app/providers/theme_provider.dart';
import 'package:controle_financeiro_app/services/auth_service.dart';
import 'package:controle_financeiro_app/services/firestore_service.dart';
import 'package:controle_financeiro_app/widgets/add_transaction_form.dart';
import 'package:controle_financeiro_app/widgets/budget_section.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum PeriodFilter { thisMonth, last7Days, lastMonth, allTime, custom }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  PeriodFilter _selectedFilter = PeriodFilter.thisMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _defaultExpenseCategories = const [
    'Alimentação', 'Transporte', 'Lazer', 'Moradia', 'Saúde', 'Outros'
  ];
  final List<String> _defaultIncomeCategories = const [
    'Salário', 'Investimentos', 'Freelance', 'Presente', 'Outros'
  ];

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
          body: Center(child: Text("Usuário não encontrado.")));
    }

    final themeProvider = Provider.of<ThemeProvider>(context);

    return StreamBuilder<Categories>(
      stream: _firestoreService.getCategoriesStream(_user!.uid),
      builder: (context, categoriesSnapshot) {
        final customCategories = categoriesSnapshot.data ??
            Categories(expenseCategories: [], incomeCategories: []);
        
        final allExpenseCategories =
            [..._defaultExpenseCategories, ...customCategories.expenseCategories]
                .toSet()
                .toList();
        final allIncomeCategories =
            [..._defaultIncomeCategories, ...customCategories.incomeCategories]
                .toSet()
                .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Visão Geral'),
            actions: [
              IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.light
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
                onPressed: () {
                  Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => AuthService().signOut(),
              ),
            ],
          ),
          body: StreamBuilder<List<FinancialTransaction>>(
            stream: _firestoreService.getTransactionsStream(_user!.uid),
            builder: (context, transactionSnapshot) {
              if (transactionSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (transactionSnapshot.hasError) {
                return Center(
                    child: Text("Erro: ${transactionSnapshot.error}"));
              }
              final allTransactions = transactionSnapshot.data ?? [];
              if (allTransactions.isEmpty) {
                return _buildEmptyState();
              }
              final filteredTransactions =
                  _getFilteredTransactions(allTransactions);
              return _buildDashboard(
                  allTransactions,
                  filteredTransactions,
                  allExpenseCategories,
                  allIncomeCategories);
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddTransactionModal(
                context, allExpenseCategories, allIncomeCategories),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  void _showAddTransactionModal(BuildContext context,
      List<String> expenseCat, List<String> incomeCat,
      {FinancialTransaction? transaction}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddTransactionForm(
        transaction: transaction,
        allExpenseCategories: expenseCat,
        allIncomeCategories: incomeCat,
      ),
    );
  }

  Widget _buildDashboard(
      List<FinancialTransaction> allTransactions,
      List<FinancialTransaction> filteredTransactions,
      List<String> allExpenseCategories,
      List<String> allIncomeCategories) {
    double totalIncome = filteredTransactions
        .where((t) => t.type == 'income')
        .fold(0, (sum, item) => sum + item.amount);
    double totalExpenses = filteredTransactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, item) => sum + item.amount);
    double balance = totalIncome - totalExpenses;
    final expenseTransactions =
        filteredTransactions.where((t) => t.type == 'expense').toList();

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
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildExpenseChart(expenseTransactions, totalExpenses),
        const SizedBox(height: 24),
        Text(
          'Metas e Orçamentos (Este Mês)',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Builder(builder: (context) {
          final now = DateTime.now();
          final expensesThisMonth = allTransactions
              .where((t) =>
                  t.type == 'expense' &&
                  t.createdAt.month == now.month &&
                  t.createdAt.year == now.year)
              .toList();

          return BudgetSection(
            expenses: expensesThisMonth,
            allExpenseCategories: allExpenseCategories,
          );
        }),
        const SizedBox(height: 24),
        _buildFilterControls(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Histórico de Transações',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (_selectedFilter != PeriodFilter.allTime)
              Text('${filteredTransactions.length} itens',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        const SizedBox(height: 8),
        _buildTransactionList(
            filteredTransactions, allExpenseCategories, allIncomeCategories),
      ],
    );
  }

  List<FinancialTransaction> _getFilteredTransactions(
      List<FinancialTransaction> allTransactions) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    switch (_selectedFilter) {
      case PeriodFilter.thisMonth:
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;
      case PeriodFilter.last7Days:
        start = now.subtract(const Duration(days: 6));
        start = DateTime(start.year, start.month, start.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case PeriodFilter.lastMonth:
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case PeriodFilter.custom:
        start = _startDate != null
            ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
            : DateTime.fromMillisecondsSinceEpoch(0);
        end = _endDate != null
            ? DateTime(
                _endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
            : now;
        break;
      case PeriodFilter.allTime:
      default:
        return allTransactions;
    }

    return allTransactions.where((t) {
      return !t.createdAt.isBefore(start) && !t.createdAt.isAfter(end);
    }).toList();
  }

  Widget _buildFilterControls() {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Filtrar Período",
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<PeriodFilter>(
              initialValue: _selectedFilter,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                    value: PeriodFilter.thisMonth, child: Text('Este Mês')),
                DropdownMenuItem(
                    value: PeriodFilter.last7Days,
                    child: Text('Últimos 7 dias')),
                DropdownMenuItem(
                    value: PeriodFilter.lastMonth, child: Text('Mês Passado')),
                DropdownMenuItem(
                    value: PeriodFilter.allTime,
                    child: Text('Todo o Período')),
                DropdownMenuItem(
                    value: PeriodFilter.custom, child: Text('Personalizado')),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedFilter = value;
                  if (_selectedFilter != PeriodFilter.custom) {
                    _startDate = null;
                    _endDate = null;
                  }
                });
              },
            ),
            if (_selectedFilter == PeriodFilter.custom)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setState(() => _startDate = date);
                        },
                        label: Text(_startDate == null
                            ? 'Início'
                            : DateFormat('dd/MM/yy').format(_startDate!)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) setState(() => _endDate = date);
                        },
                        label: Text(_endDate == null
                            ? 'Fim'
                            : DateFormat('dd/MM/yy').format(_endDate!)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseChart(
      List<FinancialTransaction> expenseTransactions, double totalExpenses) {
    if (expenseTransactions.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        child: Text('Nenhuma despesa para analisar.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );
    }
    final Map<String, double> categoryTotals = {};
    for (var transaction in expenseTransactions) {
      categoryTotals.update(
          transaction.category, (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount);
    }

    final List<Color> chartColors = [
      Theme.of(context).colorScheme.error.withOpacity(0.9),
      Theme.of(context).colorScheme.primary.withOpacity(0.8),
      Colors.amber.shade400,
      Colors.cyan.shade400,
      Colors.purple.shade400,
      Colors.orange.shade400
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
              Text("Total Gasto",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16)),
              Text(
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                    .format(totalExpenses),
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
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
                Text('Bem-vindo de volta!',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                Text(
                  _user?.email ?? 'Usuário',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long,
              size: 60, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text("Nenhuma transação encontrada.",
              style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text("Clique no botão '+' para adicionar.",
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
        _SummaryCard(
            title: 'Receitas',
            amount: income,
            color: Theme.of(context).colorScheme.secondary),
        _SummaryCard(
            title: 'Despesas',
            amount: expenses,
            color: Theme.of(context).colorScheme.error),
        _SummaryCard(
            title: 'Saldo',
            amount: balance,
            color: balance >= 0
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.error),
      ],
    );
  }

  Widget _buildTransactionList(
      List<FinancialTransaction> transactions,
      List<String> allExpenseCategories,
      List<String> allIncomeCategories) {
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Text(
            'Nenhuma transação encontrada para este período.',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          final isIncome = transaction.type == 'income';
          final formatter =
              NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

          return Dismissible(
            key: Key(transaction.id),
            direction: DismissDirection.endToStart,
            onDismissed: (direction) {
              _firestoreService.deleteTransaction(_user!.uid, transaction);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${transaction.description} removido(a).')),
              );
            },
            background: Container(
              color: Theme.of(context).colorScheme.error,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: ListTile(
              leading: IconButton(
                icon: Icon(Icons.edit_note,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                onPressed: () {
                  _showAddTransactionModal(
                    context,
                    allExpenseCategories,
                    allIncomeCategories,
                    transaction: transaction,
                  );
                },
              ),
              title: Text(transaction.description),
              subtitle: Text(transaction.category),
              trailing: Text(
                '${isIncome ? '+' : '-'} ${formatter.format(transaction.amount)}',
                style: TextStyle(
                  color: isIncome
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.error,
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatter.format(amount),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}