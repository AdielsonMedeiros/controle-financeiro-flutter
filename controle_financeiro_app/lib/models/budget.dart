// lib/models/budget.dart

class Budget {
  final Map<String, double> categories;

  Budget({
    required this.categories,
  });

  factory Budget.fromFirestore(Map<String, dynamic> data) {
    final categoriesData = <String, double>{};
    data.forEach((key, value) {
      if (value is num) {
        categoriesData[key] = value.toDouble();
      }
    });
    return Budget(categories: categoriesData);
  }
}