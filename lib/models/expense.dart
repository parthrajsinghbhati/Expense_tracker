import 'package:cloud_firestore/cloud_firestore.dart';

enum ExpenseCategory {
  food('Food'),
  travel('Travel'),
  shopping('Shopping'),
  others('Others');

  const ExpenseCategory(this.label);

  final String label;

  static ExpenseCategory fromLabel(String label) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.label == label,
      orElse: () => ExpenseCategory.others,
    );
  }
}

class Expense {
  const Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
  });

  final String? id;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category.label,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Expense.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final timestamp = data['date'];

    return Expense(
      id: doc.id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      category: ExpenseCategory.fromLabel(data['category'] as String? ?? ''),
      date: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
      note: data['note'] as String?,
    );
  }
}
