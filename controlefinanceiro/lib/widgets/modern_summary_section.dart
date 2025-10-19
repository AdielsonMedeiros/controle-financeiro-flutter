import 'package:flutter/material.dart';
import 'stats_card.dart';

class ModernSummarySection extends StatelessWidget {
  final double income;
  final double expenses;
  final double balance;
  final double? incomePercentage;
  final double? expensesPercentage;

  const ModernSummarySection({
    super.key,
    required this.income,
    required this.expenses,
    required this.balance,
    this.incomePercentage,
    this.expensesPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Card principal de saldo
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo Total',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: balance),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    'R\$ ${value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: balance >= 0
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: balance >= 0
                        ? Colors.green.withOpacity(0.3)
                        : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      balance >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      balance >= 0 ? 'Positivo' : 'Negativo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Cards de receitas e despesas
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Receitas',
                value: income,
                icon: Icons.arrow_upward_rounded,
                color: Theme.of(context).colorScheme.secondary,
                percentage: incomePercentage,
                subtitle: 'Este período',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: 'Despesas',
                value: expenses,
                icon: Icons.arrow_downward_rounded,
                color: Theme.of(context).colorScheme.error,
                percentage: expensesPercentage,
                subtitle: 'Este período',
              ),
            ),
          ],
        ),
      ],
    );
  }
}
