import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/financial_transaction.dart';

class InsightsCard extends StatelessWidget {
  final List<FinancialTransaction> transactions;

  const InsightsCard({super.key, required this.transactions});

  List<Map<String, dynamic>> _generateInsights() {
    final insights = <Map<String, dynamic>>[];
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    // Filtrar transações do mês atual e anterior
    final currentMonthExpenses = transactions.where((t) =>
        t.type == 'expense' &&
        t.createdAt.year == currentMonth.year &&
        t.createdAt.month == currentMonth.month).toList();

    final lastMonthExpenses = transactions.where((t) =>
        t.type == 'expense' &&
        t.createdAt.year == lastMonth.year &&
        t.createdAt.month == lastMonth.month).toList();

    // Insight 1: Categoria com maior gasto
    if (currentMonthExpenses.isNotEmpty) {
      final categoryTotals = <String, double>{};
      for (var t in currentMonthExpenses) {
        categoryTotals[t.category] =
            (categoryTotals[t.category] ?? 0) + t.amount;
      }

      final topCategory = categoryTotals.entries
          .reduce((a, b) => a.value > b.value ? a : b);

      insights.add({
        'icon': Icons.local_dining_rounded,
        'title': 'Categoria líder',
        'description':
            'Você gastou ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(topCategory.value)} em ${topCategory.key} este mês',
        'color': const Color(0xFFEF4444),
      });
    }

    // Insight 2: Comparação com mês anterior
    if (currentMonthExpenses.isNotEmpty && lastMonthExpenses.isNotEmpty) {
      final currentTotal =
          currentMonthExpenses.fold(0.0, (sum, t) => sum + t.amount);
      final lastTotal = lastMonthExpenses.fold(0.0, (sum, t) => sum + t.amount);
      final diff = currentTotal - lastTotal;
      final percent = (diff / lastTotal * 100).abs();

      if (diff > 0) {
        insights.add({
          'icon': Icons.trending_up_rounded,
          'title': 'Atenção aos gastos',
          'description':
              'Você gastou ${percent.toStringAsFixed(0)}% a mais que o mês passado',
          'color': Colors.orange,
        });
      } else {
        insights.add({
          'icon': Icons.celebration_rounded,
          'title': 'Parabéns!',
          'description':
              'Você economizou ${percent.toStringAsFixed(0)}% comparado ao mês passado',
          'color': Colors.green,
        });
      }
    }

    // Insight 3: Média diária de gastos
    if (currentMonthExpenses.isNotEmpty) {
      final total = currentMonthExpenses.fold(0.0, (sum, t) => sum + t.amount);
      final dailyAvg = total / now.day;

      insights.add({
        'icon': Icons.calendar_today_rounded,
        'title': 'Média diária',
        'description':
            'Você gasta em média ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(dailyAvg)} por dia',
        'color': const Color(0xFF8B5CF6),
      });
    }

    // Insight 4: Transação mais cara
    if (currentMonthExpenses.isNotEmpty) {
      final maxTransaction = currentMonthExpenses
          .reduce((a, b) => a.amount > b.amount ? a : b);

      insights.add({
        'icon': Icons.warning_rounded,
        'title': 'Maior despesa',
        'description':
            '${maxTransaction.description}: ${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(maxTransaction.amount)}',
        'color': const Color(0xFFF59E0B),
      });
    }

    // Insight 5: Frequência de transações
    if (currentMonthExpenses.length >= 10) {
      insights.add({
        'icon': Icons.receipt_long_rounded,
        'title': 'Atividade alta',
        'description':
            'Você fez ${currentMonthExpenses.length} transações este mês',
        'color': const Color(0xFF06B6D4),
      });
    }

    return insights.take(3).toList(); // Mostrar apenas 3 insights
  }

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();

    if (insights.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.lightbulb_outline_rounded,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'Adicione transações para ver insights',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
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
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFFD700).withOpacity(0.2),
                      const Color(0xFFFFA500).withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_rounded,
                  size: 20,
                  color: Color(0xFFFFA500),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Insights Inteligentes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _InsightItem(
                  icon: insight['icon'],
                  title: insight['title'],
                  description: insight['description'],
                  color: insight['color'],
                ),
              )),
        ],
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _InsightItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
