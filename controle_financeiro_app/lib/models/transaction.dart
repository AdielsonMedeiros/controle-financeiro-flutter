

import 'package:cloud_firestore/cloud_firestore.dart';

class Transaction {
  final String id;
  final String description;
  final String category;
  final double amount;
  final String type; 
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  
  factory Transaction.fromFirestore(DocumentSnapshot doc, String type) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      type: type, 
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }
}