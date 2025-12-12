import 'package:uuid/uuid.dart';

const uuid = Uuid();

enum SubscriptionCycle { monthly, yearly }

class Subscription {
  final String id;
  final String title;
  final double amount;
  final DateTime nextRenewalDate;
  final SubscriptionCycle cycle;
  final bool autoRenew; // Just for info

  Subscription({
    String? id,
    required this.title,
    required this.amount,
    required this.nextRenewalDate,
    required this.cycle,
    this.autoRenew = true,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'nextRenewalDate': nextRenewalDate.toIso8601String(),
      'cycle': cycle.index,
      'autoRenew': autoRenew ? 1 : 0,
    };
  }

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      nextRenewalDate: DateTime.parse(map['nextRenewalDate']),
      cycle: SubscriptionCycle.values[map['cycle']],
      autoRenew: map['autoRenew'] == 1,
    );
  }
}
