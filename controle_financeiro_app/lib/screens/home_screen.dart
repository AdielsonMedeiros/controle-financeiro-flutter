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
    'Alimentação',
    'Transporte',
    'Lazer',
    'Moradia',
    'Saúde',
    'Outros'
  ];

  final List<String> _defaultIncomeCategories = const [
    'Salário',
    'Investimentos',
    'Freelance',
    'Presente',
    'Outros'
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
            centerTitle: false,
            actions: [
              IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.light
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                ),
                onPressed: () {
                  Provider.of<ThemeProvider>(context, listen: false)
                      .toggleTheme();
                },
                tooltip: 'Alternar tema',
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => AuthService().signOut(),
                tooltip: 'Sair',
              ),
              const SizedBox(width: 8),
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
                allIncomeCategories,
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddTransactionModal(
                context, allExpenseCategories, allIncomeCategories),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nova'),
            elevation: 4,
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
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AddTransactionForm(
          transaction: transaction,
          allExpenseCategories: expenseCat,
          allIncomeCategories: incomeCat,
        ),
      ),
    );
  }

  Widget _buildDashboard(
    List<FinancialTransaction> allTransactions,
    List<FinancialTransaction> filteredTransactions,
    List<String> allExpenseCategories,
    List<String> allIncomeCategories,
  ) {
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        const SizedBox(height: 8),
        _buildUserInfoHeader(),
        const SizedBox(height: 24),
        _buildSummaryCards(totalIncome, totalExpenses, balance),
        const SizedBox(height: 32),
        _buildSectionHeader(context, 'Análise de Despesas', Icons.analytics_rounded),
        const SizedBox(height: 16),
        _buildExpenseChart(expenseTransactions, totalExpenses),
        const SizedBox(height: 32),
        _buildSectionHeader(context, 'Metas e Orçamentos', Icons.track_changes_rounded),
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
        const SizedBox(height: 32),
        _buildFilterControls(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(context, 'Transações', Icons.receipt_long_rounded),
            if (_selectedFilter != PeriodFilter.allTime)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${filteredTransactions.length} ${filteredTransactions.length == 1 ? 'item' : 'itens'}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTransactionList(
            filteredTransactions, allExpenseCategories, allIncomeCategories),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
        ),
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded,
                  size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text("Filtrar Período",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      )),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<PeriodFilter>(
            value: _selectedFilter,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: const [
              DropdownMenuItem(
                  value: PeriodFilter.thisMonth, child: Text('Este Mês')),
              DropdownMenuItem(
                  value: PeriodFilter.last7Days, child: Text('Últimos 7 dias')),
              DropdownMenuItem(
                  value: PeriodFilter.lastMonth, child: Text('Mês Passado')),
              DropdownMenuItem(
                  value: PeriodFilter.allTime, child: Text('Todo o Período')),
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
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _startDate = date);
                      },
                      label: Text(
                        _startDate == null
                            ? 'Início'
                            : DateFormat('dd/MM/yy').format(_startDate!),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today_rounded, size: 18),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: _startDate ?? DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _endDate = date);
                      },
                      label: Text(
                        _endDate == null
                            ? 'Fim'
                            : DateFormat('dd/MM/yy').format(_endDate!),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExpenseChart(
      List<FinancialTransaction> expenseTransactions, double totalExpenses) {
    if (expenseTransactions.isEmpty) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text('Nenhuma despesa para analisar.',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16)),
          ],
        ),
      );
    }

    final Map<String, double> categoryTotals = {};
    for (var transaction in expenseTransactions) {
      categoryTotals.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final List<Color> chartColors = [
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFF06B6D4),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
    ];

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 85,
              sections: List.generate(categoryTotals.length, (i) {
                final entry = categoryTotals.entries.elementAt(i);
                final percentage = (entry.value / totalExpenses * 100);
                return PieChartSectionData(
                  color: chartColors[i % chartColors.length],
                  value: entry.value,
                  title: '${percentage.toStringAsFixed(0)}%',
                  radius: 45,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              }),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Total Gasto",
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                      .format(totalExpenses),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(
                _user?.photoURL ??
                    'https://ui-avatars.com/api/?name=${_user?.email ?? 'A'}&background=4F46E5&color=fff',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bem-vindo de volta!',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  _user?.email ?? 'Usuário',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded,
                size: 64, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 24),
          Text("Nenhuma transação encontrada.",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text("Clique no botão 'Nova' para adicionar.",
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
        childAspectRatio: 0.95,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SummaryCard(
          title: 'Receitas',
          amount: income,
          icon: Icons.arrow_upward_rounded,
          color: Theme.of(context).colorScheme.secondary,
        ),
        _SummaryCard(
          title: 'Despesas',
          amount: expenses,
          icon: Icons.arrow_downward_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        _SummaryCard(
          title: 'Saldo',
          amount: balance,
          icon: Icons.account_balance_wallet_rounded,
          color: balance >= 0
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  Widget _buildTransactionList(
    List<FinancialTransaction> transactions,
    List<String> allExpenseCategories,
    List<String> allIncomeCategories,
  ) {
    if (transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded,
                  size: 48,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withOpacity(0.5)),
              const SizedBox(height: 12),
              Text(
                'Nenhuma transação encontrada para este período.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
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
                  content: Text('${transaction.description} removido(a).'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            background: Container(
              color: Theme.of(context).colorScheme.error,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete_rounded, color: Colors.white),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isIncome
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.error)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isIncome
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: isIncome
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.error,
                  size: 20,
                ),
              ),
              title: Text(
                transaction.description,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                transaction.category,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'} ${formatter.format(transaction.amount)}',
                    style: TextStyle(
                      color: isIncome
                          ? Theme.of(context).colorScheme.secondary
                          : Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () {
                      _showAddTransactionModal(
                        context,
                        allExpenseCategories,
                        allIncomeCategories,
                        transaction: transaction,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Editar',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => Divider(
          height: 1,
          indent: 16,
          endIndent: 16,
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatter.format(amount),
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
