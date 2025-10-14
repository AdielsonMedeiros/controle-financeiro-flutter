// Modelo para transações recorrentes
class RecurringTransaction {
  final String id;
  final String description;
  final double amount;
  final String category;
  final String type; // 'income' ou 'expense'
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime startDate;
  final DateTime? endDate;
  final int? dayOfMonth; // Para recorrências mensais (1-31)
  final int? dayOfWeek; // Para recorrências semanais (1-7)
  final bool isActive;
  final DateTime createdAt;

  RecurringTransaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.type,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.dayOfMonth,
    this.dayOfWeek,
    this.isActive = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'type': type,
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'dayOfMonth': dayOfMonth,
      'dayOfWeek': dayOfWeek,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RecurringTransaction.fromMap(Map<String, dynamic> map) {
    return RecurringTransaction(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      type: map['type'] ?? 'expense',
      frequency: map['frequency'] ?? 'monthly',
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      dayOfMonth: map['dayOfMonth'],
      dayOfWeek: map['dayOfWeek'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  DateTime? getNextOccurrence(DateTime from) {
    if (!isActive) return null;
    if (endDate != null && from.isAfter(endDate!)) return null;

    DateTime next = startDate;

    switch (frequency) {
      case 'daily':
        next = DateTime(from.year, from.month, from.day).add(const Duration(days: 1));
        break;
      case 'weekly':
        next = _getNextWeekly(from);
        break;
      case 'monthly':
        next = _getNextMonthly(from);
        break;
      case 'yearly':
        next = DateTime(from.year + 1, startDate.month, startDate.day);
        break;
    }

    if (endDate != null && next.isAfter(endDate!)) return null;
    return next;
  }

  DateTime _getNextWeekly(DateTime from) {
    final targetDay = dayOfWeek ?? startDate.weekday;
    DateTime next = from.add(const Duration(days: 1));
    while (next.weekday != targetDay) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  DateTime _getNextMonthly(DateTime from) {
    final targetDay = dayOfMonth ?? startDate.day;
    int year = from.year;
    int month = from.month + 1;

    if (month > 12) {
      month = 1;
      year++;
    }

    // Ajusta para o último dia do mês se o dia alvo não existir
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = targetDay > lastDayOfMonth ? lastDayOfMonth : targetDay;

    return DateTime(year, month, day);
  }

  RecurringTransaction copyWith({
    String? id,
    String? description,
    double? amount,
    String? category,
    String? type,
    String? frequency,
    DateTime? startDate,
    DateTime? endDate,
    int? dayOfMonth,
    int? dayOfWeek,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Modelo para parcelas
class InstallmentTransaction {
  final String id;
  final String description;
  final double totalAmount;
  final String category;
  final String type;
  final int totalInstallments;
  final int currentInstallment;
  final DateTime firstDueDate;
  final DateTime createdAt;
  final List<String> paidInstallments;

  InstallmentTransaction({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.category,
    required this.type,
    required this.totalInstallments,
    this.currentInstallment = 1,
    required this.firstDueDate,
    required this.createdAt,
    this.paidInstallments = const [],
  });

  double get installmentAmount => totalAmount / totalInstallments;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'totalAmount': totalAmount,
      'category': category,
      'type': type,
      'totalInstallments': totalInstallments,
      'currentInstallment': currentInstallment,
      'firstDueDate': firstDueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'paidInstallments': paidInstallments,
    };
  }

  factory InstallmentTransaction.fromMap(Map<String, dynamic> map) {
    return InstallmentTransaction(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      type: map['type'] ?? 'expense',
      totalInstallments: map['totalInstallments'] ?? 1,
      currentInstallment: map['currentInstallment'] ?? 1,
      firstDueDate: DateTime.parse(map['firstDueDate']),
      createdAt: DateTime.parse(map['createdAt']),
      paidInstallments: List<String>.from(map['paidInstallments'] ?? []),
    );
  }
}
