

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro_app/models/budget.dart'; 
import 'package:controle_financeiro_app/models/financial_transaction.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  

  Stream<List<FinancialTransaction>> getTransactionsStream(String userId) {
    final expensesStream = _db
        .collection('users')
        .doc(userId)
        .collection('gastos')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FinancialTransaction.fromFirestore(doc, 'expense'))
            .toList());

    final incomesStream = _db
        .collection('users')
        .doc(userId)
        .collection('receitas')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FinancialTransaction.fromFirestore(doc, 'income'))
            .toList());

    return Rx.combineLatest2(expensesStream, incomesStream,
        (List<FinancialTransaction> expenses, List<FinancialTransaction> incomes) {
      final combinedList = [...expenses, ...incomes];
      combinedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return combinedList;
    });
  }

  Future<void> deleteTransaction(String userId, FinancialTransaction transaction) async {
    final collectionName =
        transaction.type == 'expense' ? 'gastos' : 'receitas';
    await _db
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .doc(transaction.id)
        .delete();
  }

  Future<void> addTransaction(
      String userId, Map<String, dynamic> transactionData) async {
    final collectionName =
        transactionData['type'] == 'expense' ? 'gastos' : 'receitas';

    transactionData['createdAt'] = FieldValue.serverTimestamp();

    await _db
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .add(transactionData);
  }

  

  Stream<Budget> getBudgetsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('orcamentos')
        .doc('mensal')
        .snapshots()
        .map((doc) =>
            doc.exists ? Budget.fromFirestore(doc.data()!) : Budget(categories: {}));
  }

  Future<void> saveBudgets(String userId, Map<String, double> budgets) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('orcamentos')
        .doc('mensal')
        .set(budgets, SetOptions(merge: true));
  }
}