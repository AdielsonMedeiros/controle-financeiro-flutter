// lib/models/categories.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Categories {
  final List<String> expenseCategories;
  final List<String> incomeCategories;

  Categories({
    required this.expenseCategories,
    required this.incomeCategories,
  });

  factory Categories.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>? ?? {};
    return Categories(
      expenseCategories: List<String>.from(data['expenseCategories'] ?? []),
      incomeCategories: List<String>.from(data['incomeCategories'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'expenseCategories': expenseCategories,
      'incomeCategories': incomeCategories,
    };
  }
}