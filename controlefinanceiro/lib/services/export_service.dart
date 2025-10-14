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

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Header(
          level: 0,
          child: pw.Text('Relatório Financeiro', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.grey)),
        ),
        build: (context) => [
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headers: ['Data', 'Descrição', 'Categoria', 'Valor', 'Tipo'],
            data: transactions.map((t) => [
              dateFormat.format(t.createdAt),
              t.description,
              t.category,
              currencyFormat.format(t.amount),
              t.type == 'expense' ? 'Despesa' : 'Receita',
            ]).toList(),
            cellStyle: const pw.TextStyle(fontSize: 10),
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          )
        ],
      ),
    );

    return pdf.save();
  }
}