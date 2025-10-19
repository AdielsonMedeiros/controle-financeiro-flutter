

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../data/services/firestore_service.dart';
import '../../theme/financial_gradients.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo Financeiro'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF059669).withOpacity(0.1),
                const Color(0xFFD97706).withOpacity(0.05),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: FinancialGradients.backgroundSubtle(context),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            FinancialSummaryDashboard(firestoreService: firestoreService),
          ],
        ),
      ),
    );
  }
}

class FinancialSummaryDashboard extends StatelessWidget {
  final FirestoreService firestoreService;
  const FinancialSummaryDashboard({super.key, required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FinancialInsightsCard(firestoreService: firestoreService),
        const SizedBox(height: 16),
        _buildTotalAPagarCard(),
        const SizedBox(height: 16),
        _buildVencidosCard(),
        const SizedBox(height: 16),
        _buildPagoNoMesCard(),
      ],
    );
  }

  Widget _buildTotalAPagarCard() {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getUnpaidBoletosForCurrentMonthStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SummaryCard.loading(title: 'A Pagar no Mês');
        }
        double totalValue = 0;
        final count = snapshot.data!.docs.length;
        for (var doc in snapshot.data!.docs) {
          totalValue += (doc['value'] as num).toDouble();
        }
        return SummaryCard(
          title: 'A Pagar no Mês',
          value: currencyFormat.format(totalValue),
          detail: count > 0
              ? '$count boleto(s) pendente(s)'
              : 'Nenhum boleto para o mês',
          icon: PhosphorIcons.calendarBlankFill,
          color: const Color(0xFFD97706),
        );
      },
    );
  }

  Widget _buildVencidosCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getOverdueBoletosStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SummaryCard.loading(title: 'Vencidos');
        }
        final count = snapshot.data!.docs.length;

        double totalValue = 0;
        for (var doc in snapshot.data!.docs) {
          totalValue += (doc['value'] as num).toDouble();
        }
        final currencyFormat =
            NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

        return SummaryCard(
          title: 'Vencidos',
          value: count.toString(),
          detail: count > 0
              ? 'Totalizando ${currencyFormat.format(totalValue)}'
              : 'Nenhum boleto vencido',
          icon: PhosphorIcons.warningCircleFill,
          
          color: Theme.of(context).colorScheme.error,
        );
      },
    );
  }

  Widget _buildPagoNoMesCard() {
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return StreamBuilder<QuerySnapshot>(
      stream: firestoreService.getPaidBoletosForCurrentMonthStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SummaryCard.loading(title: 'Pago no Mês');
        }
        double totalValue = 0;
        final count = snapshot.data!.docs.length;
        for (var doc in snapshot.data!.docs) {
          totalValue += (doc['value'] as num).toDouble();
        }
        return SummaryCard(
          title: 'Pago no Mês',
          value: currencyFormat.format(totalValue),
          detail:
              count > 0 ? '$count boleto(s) pagos' : 'Nenhum pagamento no mês',
          icon: PhosphorIcons.checkCircleFill,
          color: const Color(0xFF059669),
        );
      },
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String? detail;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    this.detail,
    required this.icon,
    required this.color,
  }) : isLoading = false;

  const SummaryCard.loading({
    super.key,
    required this.title,
  })  : isLoading = true,
        value = '',
        detail = 'Carregando...',
        icon = PhosphorIcons.dotsThreeFill,
        color = Colors.grey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = isLoading ? theme.colorScheme.surfaceContainerHighest : color;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor.withOpacity(0.8), cardColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(right: 100.0, top: 8.0, bottom: 8.0),
              child: LinearProgressIndicator(
                backgroundColor: Colors.white24,
                color: Colors.white,
              ),
            )
          else
            Text(
              value,
              style: theme.textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          if (detail != null)
            Text(
              detail!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
            ),
        ],
      ),
    );
  }
}

class FinancialInsightsCard extends StatefulWidget {
  final FirestoreService firestoreService;

  const FinancialInsightsCard({super.key, required this.firestoreService});

  @override
  State<FinancialInsightsCard> createState() => _FinancialInsightsCardState();
}

class _FinancialInsightsCardState extends State<FinancialInsightsCard> {
  bool _isLoading = true;
  String? _comparisonMessage;
  String? _topCategoryMessage;

  @override
  void initState() {
    super.initState();
    _calculateInsights();
  }

  Future<void> _calculateInsights() async {
    final now = DateTime.now();
    final startOfCurrentMonth = DateTime(now.year, now.month, 1);
    final endOfCurrentMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final startOfPreviousMonth = DateTime(now.year, now.month - 1, 1);
    final endOfPreviousMonth = DateTime(now.year, now.month, 0, 23, 59, 59);

    final results = await Future.wait([
      widget.firestoreService
          .getPaidBoletosByDateRange(startOfCurrentMonth, endOfCurrentMonth),
      widget.firestoreService
          .getPaidBoletosByDateRange(startOfPreviousMonth, endOfPreviousMonth),
    ]);

    final currentMonthBoletos = results[0];
    final previousMonthBoletos = results[1];
    final currencyFormat =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    double totalCurrentMonth = 0;
    Map<String, double> currentMonthSpendingByTag = {};

    for (var boleto in currentMonthBoletos) {
      totalCurrentMonth += boleto.value;
      currentMonthSpendingByTag.update(
          boleto.tag, (value) => value + boleto.value,
          ifAbsent: () => boleto.value);
    }

    if (currentMonthSpendingByTag.isNotEmpty) {
      final topCategoryEntry = currentMonthSpendingByTag.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      _topCategoryMessage =
          "Sua maior despesa este mês foi com '${topCategoryEntry.key}'.";
    } else {
      _topCategoryMessage = "Você ainda não teve despesas este mês.";
    }

    double totalPreviousMonth = 0;
    for (var boleto in previousMonthBoletos) {
      totalPreviousMonth += boleto.value;
    }

    if (totalPreviousMonth > 0) {
      final difference = totalCurrentMonth - totalPreviousMonth;
      if (difference > 0) {
        _comparisonMessage =
            "Você gastou ${currencyFormat.format(difference.abs())} a mais que no mês passado.";
      } else if (difference < 0) {
        _comparisonMessage =
            "Você economizou ${currencyFormat.format(difference.abs())} em relação ao mês passado.";
      } else {
        _comparisonMessage =
            "Seus gastos se mantiveram os mesmos do mês passado.";
      }
    } else {
      _comparisonMessage = "Não há dados do mês passado para comparação.";
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SummaryCard.loading(title: 'Calculando Insights...');
    }

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: FinancialGradients.cardGradient(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.secondary.withOpacity(0.2),
                        theme.colorScheme.tertiary.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(PhosphorIcons.sparkleFill,
                      color: theme.colorScheme.secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Insights Rápidos',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_comparisonMessage != null)
              _buildInsightRow(
                context,
                icon: PhosphorIcons.chartLineUpFill,
                text: _comparisonMessage!,
                
                color: theme.colorScheme.primary,
              ),
            const SizedBox(height: 12),
            if (_topCategoryMessage != null)
              _buildInsightRow(
                context,
                icon: PhosphorIcons.tagFill,
                text: _topCategoryMessage!,
                
                color: theme.colorScheme.tertiary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(BuildContext context,
      {required IconData icon, required String text, required Color color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.2),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
          ),
        ),
      ],
    );
  }
}
