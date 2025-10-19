// lib/services/export_service.dart

import 'dart:io';
import 'package:controlefinanceiro/models/financial_transaction.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class ExportService {
  final BuildContext context;

  ExportService(this.context);

  Future<void> exportTransactions({
    required List<FinancialTransaction> transactions,
    required String format, // 'CSV' ou 'PDF'
    DateTime? startDate,
    DateTime? endDate,
    String? periodLabel,
  }) async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma transação para exportar neste período.')),
      );
      return;
    }

    try {
      final String fileName = 'relatorio_financeiro_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
      final Directory dir = await getTemporaryDirectory();
      final String path = '${dir.path}/$fileName.${format.toLowerCase()}';
      
      File file;
      if (format == 'CSV') {
        final csvData = _generateCsv(transactions);
        file = File(path);
        await file.writeAsString(csvData);
      } else { // PDF
        final pdfData = await _generatePdf(transactions);
        file = File(path);
        await file.writeAsBytes(pdfData);
      }

      await Share.shareXFiles([XFile(path)], text: 'Segue seu relatório financeiro.');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar arquivo: $e')),
      );
    }
  }

  String _generateCsv(List<FinancialTransaction> transactions) {
    final List<List<dynamic>> rows = [];
    // Cabeçalho
    rows.add(['Data', 'Descrição', 'Categoria', 'Valor (R\$)', 'Tipo']);

    // Linhas de dados
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: '');
    for (final t in transactions) {
      rows.add([
        DateFormat('dd/MM/yyyy').format(t.createdAt),
        t.description,
        t.category,
        formatter.format(t.amount),
        t.type == 'expense' ? 'Despesa' : 'Receita',
      ]);
    }
    return const ListToCsvConverter().convert(rows);
  }

  Future<Uint8List> _generatePdf(List<FinancialTransaction> transactions) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Calcular totais
    double totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
    double totalExpenses = transactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
    double balance = totalIncome - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Relatório Financeiro',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Divider(thickness: 2),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
        build: (context) => [
          // Resumo Financeiro
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Resumo do Período',
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Receitas:', style: const pw.TextStyle(fontSize: 12)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          currencyFormat.format(totalIncome),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Despesas:', style: const pw.TextStyle(fontSize: 12)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          currencyFormat.format(totalExpenses),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.red700,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Saldo:', style: const pw.TextStyle(fontSize: 12)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          currencyFormat.format(balance),
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: balance >= 0 ? PdfColors.green700 : PdfColors.red700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),
          // Tabela de Transações
          pw.Text(
            'Transações (${transactions.length})',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headers: ['Data', 'Descrição', 'Categoria', 'Valor', 'Tipo'],
            data: transactions.map((t) => [
              dateFormat.format(t.createdAt),
              t.description,
              t.category,
              currencyFormat.format(t.amount),
              t.type == 'expense' ? 'Despesa' : 'Receita',
            ]).toList(),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.center,
            },
            oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}