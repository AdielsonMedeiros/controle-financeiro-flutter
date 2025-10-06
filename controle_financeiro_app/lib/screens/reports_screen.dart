// lib/screens/reports_screen.dart

import 'package:controle_financeiro_app/models/financial_transaction.dart';
import 'package:controle_financeiro_app/services/export_service.dart';
import 'package:controle_financeiro_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  Future<void> _showExportDialog(List<FinancialTransaction> allTransactions) async {
    String selectedFormat = 'CSV';
    String selectedPeriod = 'month';
    DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime endDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.download_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('Exportar Relatório',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              )),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Período:',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...['month', 'all', 'custom'].map((period) {
                    final titles = {
                      'month': 'Mês Atual',
                      'all': 'Todo o Período',
                      'custom': 'Período Personalizado'
                    };
                    return RadioListTile<String>(
                      title: Text(titles[period]!),
                      value: period,
                      groupValue: selectedPeriod,
                      onChanged: (v) => setModalState(() => selectedPeriod = v!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.zero,
                    );
                  }),
                  if (selectedPeriod == 'custom')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.calendar_today_rounded, size: 18),
                              label: Text(
                                  'Início: ${DateFormat('dd/MM/yy').format(startDate)}'),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: startDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null)
                                  setModalState(() => startDate = date);
                              },
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
                              label: Text(
                                  'Fim: ${DateFormat('dd/MM/yy').format(endDate)}'),
                              onPressed: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: endDate,
                                  firstDate: startDate,
                                  lastDate: DateTime.now(),
                                );
                                if (date != null)
                                  setModalState(() => endDate = date);
                              },
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
                  const SizedBox(height: 24),
                  Text('Formato:',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: ['CSV', 'PDF'].map((format) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(format),
                            selected: selectedFormat == format,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => selectedFormat = format);
                              }
                            },
                            selectedColor:
                                Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: selectedFormat == format
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: selectedFormat == format
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded),
                      label: const Text(
                        'Exportar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: () {
                        List<FinancialTransaction> transactionsToExport;
                        if (selectedPeriod == 'all') {
                          transactionsToExport = allTransactions;
                        } else if (selectedPeriod == 'month') {
                          final now = DateTime.now();
                          final start = DateTime(now.year, now.month, 1);
                          transactionsToExport = allTransactions
                              .where((t) => !t.createdAt.isBefore(start))
                              .toList();
                        } else {
                          final end = DateTime(
                              endDate.year, endDate.month, endDate.day, 23, 59, 59);
                          transactionsToExport = allTransactions
                              .where((t) =>
                                  !t.createdAt.isBefore(startDate) &&
                                  !t.createdAt.isAfter(end))
                              .toList();
                        }

                        final exportService = ExportService(context);
                        exportService.exportTransactions(
                          transactions: transactionsToExport,
                          format: selectedFormat,
                        );
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(
          body: Center(child: Text("Usuário não encontrado.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        centerTitle: false,
        actions: [
          StreamBuilder<List<FinancialTransaction>>(
            stream: _firestoreService.getTransactionsStream(_user!.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }

              return IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () => _showExportDialog(snapshot.data!),
                tooltip: 'Exportar Relatório',
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: _firestoreService.getTransactionsStream(_user!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Erro: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                      Icons.bar_chart_rounded,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Dados insuficientes para gerar relatórios.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final transactions = snapshot.data!;
          return _buildReports(context, transactions);
        },
      ),
    );
  }

  Widget _buildReports(
      BuildContext context, List<FinancialTransaction> transactions) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildReportCard(
          context: context,
          title: 'Evolução de Gastos e Receitas',
          subtitle:
              'Comparação de suas receitas e despesas ao longo dos últimos 6 meses.',
          icon: Icons.trending_up_rounded,
          chart: _buildMonthlyEvolutionChart(transactions),
        ),
        const SizedBox(height: 24),
        _buildReportCard(
          context: context,
          title: 'Comparação de Categorias',
          subtitle:
              'Analise quais categorias têm o maior impacto em suas despesas.',
          icon: Icons.pie_chart_rounded,
          chart: _buildCategoryComparisonChart(transactions),
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget chart,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon,
                    size: 24, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: 300, child: chart),
        ],
      ),
    );
  }

  Widget _buildMonthlyEvolutionChart(
      List<FinancialTransaction> transactions) {
    final monthlyTotals = <String, Map<String, double>>{};
    final now = DateTime.now();

    for (var i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('yyyy-MM').format(month);
      monthlyTotals[monthKey] = {'income': 0.0, 'expense': 0.0};
    }

    for (var t in transactions) {
      final monthKey = DateFormat('yyyy-MM').format(t.createdAt);
      if (monthlyTotals.containsKey(monthKey)) {
        monthlyTotals[monthKey]![t.type] =
            (monthlyTotals[monthKey]![t.type] ?? 0) + t.amount;
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: monthlyTotals.values
                .map((e) => [e['income']!, e['expense']!].reduce((a, b) => a > b ? a : b))
                .reduce((a, b) => a > b ? a : b) *
            1.2,
        barGroups: List.generate(monthlyTotals.length, (index) {
          final entry = monthlyTotals.entries.elementAt(index);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value['income']!,
                color: Theme.of(context).colorScheme.secondary,
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
              BarChartRodData(
                toY: entry.value['expense']!,
                color: Theme.of(context).colorScheme.error,
                width: 14,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= monthlyTotals.length) return const Text('');
                final monthKey = monthlyTotals.keys.elementAt(value.toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MMM', 'pt_BR')
                        .format(DateFormat('yyyy-MM').parse(monthKey)),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildCategoryComparisonChart(
      List<FinancialTransaction> transactions) {
    final categoryTotals = <String, double>{};
    transactions.where((t) => t.type == 'expense').forEach((t) {
      categoryTotals.update(t.category, (value) => value + t.amount,
          ifAbsent: () => t.amount);
    });

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategories = sortedCategories.take(5).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topCategories.isEmpty
            ? 100
            : topCategories.first.value * 1.2,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = topCategories[group.x.toInt()];
              return BarTooltipItem(
                '${entry.key}\n${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(entry.value)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        barGroups: List.generate(topCategories.length, (index) {
          final entry = topCategories[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value,
                color: Theme.of(context).colorScheme.primary,
                width: 32,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              )
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= topCategories.length) return const Text('');
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    topCategories[value.toInt()].key,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}
