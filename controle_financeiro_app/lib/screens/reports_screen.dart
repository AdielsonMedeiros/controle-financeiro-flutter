// lib/screens/reports_screen.dart

import 'package:controle_financeiro_app/models/financial_transaction.dart';
import 'package:controle_financeiro_app/services/export_service.dart'; // <<< IMPORTE O NOVO SERVIÇO
import 'package:controle_financeiro_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Mude para StatefulWidget para podermos gerenciar o estado
class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;

  // Função para mostrar o diálogo de exportação
  Future<void> _showExportDialog(List<FinancialTransaction> allTransactions) async {
    // Variáveis para o controle do diálogo
    String selectedFormat = 'CSV'; // 'CSV' ou 'PDF'
    String selectedPeriod = 'month'; // 'month', 'custom', 'all'
    DateTime startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
    DateTime endDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        // Usamos StatefulBuilder para que o diálogo tenha seu próprio estado
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16, right: 16, top: 20
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Exportar Relatório', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  
                  // SELEÇÃO DE PERÍODO
                  const Text('Período:', style: TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<String>(
                    title: const Text('Mês Atual'),
                    value: 'month',
                    groupValue: selectedPeriod,
                    onChanged: (v) => setModalState(() => selectedPeriod = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Todo o Período'),
                    value: 'all',
                    groupValue: selectedPeriod,
                    onChanged: (v) => setModalState(() => selectedPeriod = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('Período Personalizado'),
                    value: 'custom',
                    groupValue: selectedPeriod,
                    onChanged: (v) => setModalState(() => selectedPeriod = v!),
                  ),
                  if (selectedPeriod == 'custom')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text('Início: ${DateFormat('dd/MM/yy').format(startDate)}'),
                          onPressed: () async {
                            final date = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                            if (date != null) setModalState(() => startDate = date);
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.calendar_today),
                          label: Text('Fim: ${DateFormat('dd/MM/yy').format(endDate)}'),
                          onPressed: () async {
                            final date = await showDatePicker(context: context, initialDate: endDate, firstDate: startDate, lastDate: DateTime.now());
                            if (date != null) setModalState(() => endDate = date);
                          },
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 20),
                  
                  // SELEÇÃO DE FORMATO
                  const Text('Formato:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('CSV'),
                          value: 'CSV',
                          groupValue: selectedFormat,
                          onChanged: (v) => setModalState(() => selectedFormat = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('PDF'),
                          value: 'PDF',
                          groupValue: selectedFormat,
                          onChanged: (v) => setModalState(() => selectedFormat = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // BOTÃO DE AÇÃO
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Exportar'),
                      onPressed: () {
                        // 1. Filtrar transações
                        List<FinancialTransaction> transactionsToExport;
                        if (selectedPeriod == 'all') {
                          transactionsToExport = allTransactions;
                        } else if (selectedPeriod == 'month') {
                           final now = DateTime.now();
                           final start = DateTime(now.year, now.month, 1);
                           transactionsToExport = allTransactions.where((t) => !t.createdAt.isBefore(start)).toList();
                        } else { // custom
                           final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
                           transactionsToExport = allTransactions.where((t) => !t.createdAt.isBefore(startDate) && !t.createdAt.isAfter(end)).toList();
                        }
                        
                        // 2. Chamar o serviço de exportação
                        final exportService = ExportService(context);
                        exportService.exportTransactions(
                          transactions: transactionsToExport,
                          format: selectedFormat
                        );
                        
                        Navigator.of(context).pop(); // Fecha o diálogo
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
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
      return const Scaffold(body: Center(child: Text("Usuário não encontrado.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        // ADICIONE O BOTÃO AQUI
        actions: [
          StreamBuilder<List<FinancialTransaction>>(
            stream: _firestoreService.getTransactionsStream(_user!.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink(); // Não mostra o botão se não há dados
              }
              return IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () => _showExportDialog(snapshot.data!),
                tooltip: 'Exportar Relatório',
              );
            },
          ),
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
            return const Center(child: Text("Dados insuficientes para gerar relatórios."));
          }

          final transactions = snapshot.data!;
          return _buildReports(context, transactions);
        },
      ),
    );
  }
  
  Widget _buildReports(BuildContext context, List<FinancialTransaction> transactions) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildReportCard(
          context: context,
          title: 'Evolução de Gastos e Receitas',
          subtitle: 'Comparação de suas receitas e despesas ao longo dos últimos 6 meses.',
          chart: _buildMonthlyEvolutionChart(transactions),
        ),
        const SizedBox(height: 24),
        _buildReportCard(
          context: context,
          title: 'Comparação de Categorias (Despesas)',
          subtitle: 'Analise quais categorias têm o maior impacto em suas despesas.',
          chart: _buildCategoryComparisonChart(transactions),
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget chart,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            SizedBox(height: 300, child: chart),
          ],
        ),
      ),
    );
  }
  
  
  Widget _buildMonthlyEvolutionChart(List<FinancialTransaction> transactions) {
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
        monthlyTotals[monthKey]![t.type] = (monthlyTotals[monthKey]![t.type] ?? 0) + t.amount;
      }
    }
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: List.generate(monthlyTotals.length, (index) {
          final entry = monthlyTotals.entries.elementAt(index);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: entry.value['income']!, color: Colors.green, width: 15, borderRadius: BorderRadius.zero),
              BarChartRodData(toY: entry.value['expense']!, color: Colors.red, width: 15, borderRadius: BorderRadius.zero),
            ],
          );
        }),
        
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            final monthKey = monthlyTotals.keys.elementAt(value.toInt());
            return Text(DateFormat('MMM', 'pt_BR').format(DateFormat('yyyy-MM').parse(monthKey)));
          })),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
  
  
  Widget _buildCategoryComparisonChart(List<FinancialTransaction> transactions) {
    final categoryTotals = <String, double>{};
    transactions.where((t) => t.type == 'expense').forEach((t) {
      categoryTotals.update(t.category, (value) => value + t.amount, ifAbsent: () => t.amount);
    });

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Pega apenas as 5 categorias com maiores gastos para melhor visualização
    final topCategories = sortedCategories.take(5).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final entry = topCategories[group.x.toInt()];
              return BarTooltipItem(
                '${entry.key}\n${NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(entry.value)}',
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),
        barGroups: List.generate(topCategories.length, (index) {
          final entry = topCategories[index];
          return BarChartGroupData(
            x: index,
            barRods: [BarChartRodData(toY: entry.value, color: Colors.indigo, width: 20, borderRadius: BorderRadius.zero)],
          );
        }),
        
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            if (value.toInt() >= topCategories.length) return const Text('');
            return Text(topCategories[value.toInt()].key, style: const TextStyle(fontSize: 10));
          }, reservedSize: 30)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}