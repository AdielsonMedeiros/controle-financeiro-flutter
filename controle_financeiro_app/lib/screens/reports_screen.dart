// lib/screens/reports_screen.dart

import 'package:controle_financeiro_app/models/financial_transaction.dart';
import 'package:controle_financeiro_app/services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Usuário não encontrado.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
      ),
      body: StreamBuilder<List<FinancialTransaction>>(
        stream: firestoreService.getTransactionsStream(user.uid),
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
          title: 'Comparação de Categorias',
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
  
  // --- GRÁFICO DE EVOLUÇÃO MENSAL (CORRIGIDO) ---
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
        // --- ESTRUTURA CORRIGIDA ABAIXO ---
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
  
  // --- GRÁFICO DE COMPARAÇÃO DE CATEGORIAS (CORRIGIDO) ---
  Widget _buildCategoryComparisonChart(List<FinancialTransaction> transactions) {
    final categoryTotals = <String, double>{};
    transactions.where((t) => t.type == 'expense').forEach((t) {
      categoryTotals.update(t.category, (value) => value + t.amount, ifAbsent: () => t.amount);
    });

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: List.generate(sortedCategories.length, (index) {
          final entry = sortedCategories[index];
          return BarChartGroupData(
            x: index,
            barRods: [BarChartRodData(toY: entry.value, color: Colors.indigo, width: 15, borderRadius: BorderRadius.zero)],
          );
        }),
        // --- ESTRUTURA CORRIGIDA ABAIXO ---
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
            if (value.toInt() >= sortedCategories.length) return const Text('');
            return Text(sortedCategories[value.toInt()].key, style: const TextStyle(fontSize: 10));
          }, reservedSize: 80)),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}