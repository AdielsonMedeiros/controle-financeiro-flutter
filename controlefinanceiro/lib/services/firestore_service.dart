// lib/services/firestore_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controlefinanceiro/models/budget.dart';
import 'package:controlefinanceiro/models/categories.dart';
import 'package:controlefinanceiro/models/financial_transaction.dart';
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

  Future<void> updateTransaction(
      String userId, Map<String, dynamic> transactionData) async {
    final collectionName =
        transactionData['type'] == 'expense' ? 'gastos' : 'receitas';
    final transactionId = transactionData['id'];

    transactionData.remove('id');

    await _db
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .doc(transactionId)
        .update(transactionData);
  }

  Future<void> deleteTransaction(
      String userId, FinancialTransaction transaction) async {
    final collectionName =
        transaction.type == 'expense' ? 'gastos' : 'receitas';
    await _db
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .doc(transaction.id)
        .delete();
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
  
  Stream<Categories> getCategoriesStream(String userId) {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('config')
        .doc('categories');

    return docRef.snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Categories.fromFirestore(snapshot);
      } else {
        return Categories(expenseCategories: [], incomeCategories: []);
      }
    });
  }

  Future<void> saveCategories(String userId, Categories categories) async {
    final docRef = _db
        .collection('users')
        .doc(userId)
        .collection('config')
        .doc('categories');

    await docRef.set(categories.toFirestore(), SetOptions(merge: true));
  }
}