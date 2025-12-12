import 'package:uuid/uuid.dart';
import '../helpers/constants.dart';

const uuid = Uuid();

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String categoryId;
  final TransactionType type;
  final Mood mood;
  final WalletType wallet;
  final String? description;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryId,
    required this.type,
    this.mood = Mood.neutral,
    this.wallet = WalletType.upi,
    this.description,
  }) : id = id ?? uuid.v4();

  // Convert to Map for Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'categoryId': categoryId,
      'type': type.index, // Store as int
      'mood': mood.index, // Store as int
      'wallet': wallet.index, // Store as int
      'description': description ?? '',
    };
  }

  // Create from Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      categoryId: map['categoryId'],
      type: TransactionType.values[map['type']],
      mood: Mood.values[map['mood']],
      wallet: WalletType.values[map['wallet']],
      description: map['description'],
    );
  }
}
