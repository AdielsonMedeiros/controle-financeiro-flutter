// lib/models/financial_transaction.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // Import corrigido

class FinancialTransaction { // Classe Renomeada
  final String id;
  final String description;
  final String category;
  final double amount;
  final String type; // 'expense' ou 'income'
  final DateTime createdAt;

  FinancialTransaction({ // Construtor Renomeado
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  factory FinancialTransaction.fromFirestore(DocumentSnapshot doc, String type) { // Método Renomeado
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return FinancialTransaction( // Objeto Renomeado
      id: doc.id,
      type: type,
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}