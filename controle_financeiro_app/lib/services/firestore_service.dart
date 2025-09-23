// lib/services/firestore_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro_app/models/budget.dart';
import 'package:controle_financeiro_app/models/financial_transaction.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<FinancialTransaction>> getTransactionsStream(String userId) {
    // ... (código existente inalterado) ...
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
    // ... (código existente inalterado) ...
    final collectionName =
        transactionData['type'] == 'expense' ? 'gastos' : 'receitas';

    transactionData['createdAt'] = FieldValue.serverTimestamp();

    await _db
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .add(transactionData);
  }

  // --- NOVO MÉTODO PARA ATUALIZAR TRANSAÇÕES ---
  Future<void> updateTransaction(
      String userId, Map<String, dynamic> transactionData) async {
    // O tipo e o ID devem estar presentes nos dados da transação
    final collectionName =
        transactionData['type'] == 'expense' ? 'gastos' : 'receitas';
    final transactionId = transactionData['id'];

    // Removemos o id e o tipo do mapa para não salvá-los dentro do documento
    transactionData.remove('id');
    // O tipo já está implícito pelo nome da coleção

    await _db
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .doc(transactionId)
        .update(transactionData);
  }

  Future<void> deleteTransaction(
      String userId, FinancialTransaction transaction) async {
    // ... (código existente inalterado) ...
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
    // ... (código existente inalterado) ...
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
    // ... (código existente inalterado) ...
    await _db
        .collection('users')
        .doc(userId)
        .collection('orcamentos')
        .doc('mensal')
        .set(budgets, SetOptions(merge: true));
  }
}