import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/financial_transaction.dart';

class ComparisonCard extends StatelessWidget {
  final List<FinancialTransaction> transactions;

  const ComparisonCard({super.key, required this.transactions});

  Map<String, double> _getMonthlyComparison() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    double currentExpenses = 0;
    double lastExpenses = 0;
    double currentIncome = 0;
    double lastIncome = 0;

    for (var transaction in transactions) {
      final isCurrentMonth = transaction.createdAt.year == currentMonth.year &&
          transaction.createdAt.month == currentMonth.month;
      final isLastMonth = transaction.createdAt.year == lastMonth.year &&
          transaction.createdAt.month == lastMonth.month;

      if (transaction.type == 'expense') {
        if (isCurrentMonth) currentExpenses += transaction.amount;
        if (isLastMonth) lastExpenses += transaction.amount;
      } else {
        if (isCurrentMonth) currentIncome += transaction.amount;
        if (isLastMonth) lastIncome += transaction.amount;
      }
    }

    return {
      'currentExpenses': currentExpenses,
      'lastExpenses': lastExpenses,
      'currentIncome': currentIncome,
      'lastIncome': lastIncome,
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = _getMonthlyComparison();
    final expensesDiff = data['currentExpenses']! - data['lastExpenses']!;
    final expensesPercent = data['lastExpenses']! > 0
        ? (expensesDiff / data['lastExpenses']!) * 100
        : 0.0;

    final incomeDiff = data['currentIncome']! - data['lastIncome']!;
    final incomePercent = data['lastIncome']! > 0
        ? (incomeDiff / data['lastIncome']!) * 100
        : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.08),
            Theme.of(context).colorScheme.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Comparativo Mensal',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ComparisonItem(
                  label: 'Gastos',
                  currentValue: data['currentExpenses']!,
                  lastValue: data['lastExpenses']!,
                  percentChange: expensesPercent,
                  color: Theme.of(context).colorScheme.error,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ComparisonItem(
                  label: 'Receitas',
                  currentValue: data['currentIncome']!,
                  lastValue: data['lastIncome']!,
                  percentChange: incomePercent,
                  color: Theme.of(context).colorScheme.secondary,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonItem extends StatelessWidget {
  final String label;
  final double currentValue;
  final double lastValue;
  final double percentChange;
  final Color color;
  final IconData icon;

  const _ComparisonItem({
    required this.label,
    required this.currentValue,
    required this.lastValue,
    required this.percentChange,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isIncrease = percentChange > 0;
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatter.format(currentValue),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                isIncrease
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: isIncrease
                    ? (label == 'Receitas' ? Colors.green : Colors.red)
                    : (label == 'Receitas' ? Colors.red : Colors.green),
              ),
              const SizedBox(width: 4),
              Text(
                '${percentChange.abs().toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isIncrease
                      ? (label == 'Receitas' ? Colors.green : Colors.red)
                      : (label == 'Receitas' ? Colors.red : Colors.green),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'vs mês passado',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
