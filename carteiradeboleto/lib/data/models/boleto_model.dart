import 'package:cloud_firestore/cloud_firestore.dart';

class Boleto {
  final String id;
  final String description;
  final double value;
  final DateTime dueDate;
  final String? barcode;
  final bool isPaid;
  final Timestamp? paidAt;
  final String tag;
  final String? originalRequestId;
  final String? sentFromId;
  // ===== CAMPO ADICIONADO =====
  final String? originalSenderBoletoId;

  Boleto({
    required this.id,
    required this.description,
    required this.value,
    required this.dueDate,
    this.barcode,
    required this.isPaid,
    this.paidAt,
    required this.tag,
    this.originalRequestId,
    this.sentFromId,
    // Adicionado ao construtor
    this.originalSenderBoletoId,
  });

  factory Boleto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Boleto(
      id: doc.id,
      description: data['description'] ?? '',
      value: (data['value'] ?? 0).toDouble(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      barcode: data['barcode'],
      isPaid: data['isPaid'] ?? false,
      paidAt: data['paidAt'] as Timestamp?,
      tag: data['tag'] ?? 'Outros',
      originalRequestId: data['originalRequestId'],
      sentFromId: data['sentFromId'],
      // Lendo o novo campo
      originalSenderBoletoId: data['originalSenderBoletoId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'value': value,
      'dueDate': Timestamp.fromDate(dueDate),
      'barcode': barcode,
      'isPaid': isPaid,
      'paidAt': paidAt,
      'tag': tag,
      'originalRequestId': originalRequestId,
      'sentFromId': sentFromId,
      // Adicionando o novo campo
      'originalSenderBoletoId': originalSenderBoletoId,
    };
  }

  Boleto copyWith({
    String? id,
    String? description,
    double? value,
    DateTime? dueDate,
    String? barcode,
    bool? isPaid,
    Timestamp? paidAt,
    String? tag,
    String? originalRequestId,
    String? sentFromId,
    // Adicionado ao copyWith
    String? originalSenderBoletoId,
  }) {
    return Boleto(
      id: id ?? this.id,
      description: description ?? this.description,
      value: value ?? this.value,
      dueDate: dueDate ?? this.dueDate,
      barcode: barcode ?? this.barcode,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      tag: tag ?? this.tag,
      originalRequestId: originalRequestId ?? this.originalRequestId,
      sentFromId: sentFromId ?? this.sentFromId,
      // Atualizando o novo campo
      originalSenderBoletoId:
          originalSenderBoletoId ?? this.originalSenderBoletoId,
    );
  }
}
