// lib/models/transaction.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String id;
  final String description;
  final String category;
  final double amount;
  final String type; // 'expense' ou 'income'
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  // Constrói um objeto Transaction a partir de um documento do Firestore
  factory Transaction.fromFirestore(DocumentSnapshot doc, String type) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      type: type, // O tipo é passado como parâmetro
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      // Converte o Timestamp do Firebase para um DateTime do Dart
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}