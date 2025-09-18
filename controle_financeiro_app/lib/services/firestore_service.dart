// lib/services/firestore_service.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:controle_financeiro_app/models/financial_transaction.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Busca todas as transações (gastos e receitas) de um usuário
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

    // Combina os dois streams em um só e ordena pela data
    return Rx.combineLatest2(expensesStream, incomesStream,
        (List<FinancialTransaction> expenses, List<FinancialTransaction> incomes) {
      final combinedList = [...expenses, ...incomes];
      // Ordena a lista combinada, da transação mais recente para a mais antiga
      combinedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return combinedList;
    });
  }

  // Função para deletar uma transação
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

  // Função para adicionar uma nova transação
  Future<void> addTransaction(
      String userId, Map<String, dynamic> transactionData) async {
    final collectionName =
        transactionData['type'] == 'expense' ? 'gastos' : 'receitas';

    // Adiciona a data de criação no momento em que a transação chega no servidor
    transactionData['createdAt'] = FieldValue.serverTimestamp();

    await _db
        .collection('users')
        .doc(userId)
        .collection(collectionName)
        .add(transactionData);
  }
}