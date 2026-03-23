import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../helpers/constants.dart';

const uuid = Uuid();

class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String time; // "HH:mm" format, e.g. "14:30"
  final String categoryId;
  final TransactionType type;
  final Mood mood;
  final WalletType wallet;
  final String? description;
  final TransactionOrigin origin;
  final String? linkedGroupId;
  final bool isStarred;

  Transaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    String? time,
    required this.categoryId,
    required this.type,
    this.mood = Mood.neutral,
    this.wallet = WalletType.upi,
    this.description,
    this.origin = TransactionOrigin.manual,
    this.linkedGroupId,
    this.isStarred = false,
  }) : id = id ?? uuid.v4(),
       time = time ?? '${TimeOfDay.now().hour.toString().padLeft(2, '0')}:${TimeOfDay.now().minute.toString().padLeft(2, '0')}';

  /// Parse stored time string into hour (0-23)
  int get hour {
    final parts = time.split(':');
    return parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
  }

  /// Parse stored time string into minute (0-59)
  int get minute {
    final parts = time.split(':');
    return parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  }

  /// Get TimeOfDay from the stored time string
  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  /// Format time for display (e.g. "2:30 PM")
  String get formattedTime {
    final h = hour;
    final m = minute;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayHour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$displayHour:${m.toString().padLeft(2, '0')} $period';
  }

  // Convert to Map for Database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'time': time,
      'categoryId': categoryId,
      'type': type.index,
      'mood': mood.index,
      'wallet': wallet.index,
      'description': description,
      'origin': origin.index,
      'linkedGroupId': linkedGroupId,
      'isStarred': isStarred ? 1 : 0,
    };
  }

  // Create from Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      time: map['time'] ?? '00:00',
      categoryId: map['categoryId'],
      type: TransactionType.values[map['type']],
      mood: Mood.values[map['mood']],
      wallet: WalletType.values[map['wallet']],
      description: map['description'],
      origin: map.containsKey('origin') ? TransactionOrigin.values[map['origin']] : TransactionOrigin.manual,
      linkedGroupId: map['linkedGroupId'],
      isStarred: (map['isStarred'] ?? 0) == 1,
    );
  }
}
