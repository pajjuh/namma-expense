import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import '../helpers/constants.dart';

const uuid = Uuid();

// We add new cycles to the end of the enum so we don't break existing saved DB integer indexes (0=monthly, 1=yearly)
enum SubscriptionCycle { monthly, yearly, quarterly, halfYearly }

extension SubscriptionCycleExtension on SubscriptionCycle {
  String get displayName {
    switch (this) {
      case SubscriptionCycle.monthly:
        return 'Monthly';
      case SubscriptionCycle.yearly:
        return 'Yearly (12 Months)';
      case SubscriptionCycle.quarterly:
        return 'Quarterly (3 Months)';
      case SubscriptionCycle.halfYearly:
        return 'Half-Yearly (6 Months)';
    }
  }
}

class Subscription {
  final String id;
  final String title;
  final double amount;
  final DateTime nextRenewalDate;
  final SubscriptionCycle cycle;
  final bool autoRenew; // Just for info
  final SubscriptionType type;
  final int? totalDurationDays;
  final int? cycleDays;

  Subscription({
    String? id,
    required this.title,
    required this.amount,
    required this.nextRenewalDate,
    required this.cycle,
    this.autoRenew = true,
    this.type = SubscriptionType.recurring,
    this.totalDurationDays,
    this.cycleDays,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'nextRenewalDate': nextRenewalDate.toIso8601String(),
      'cycle': cycle.index,
      'autoRenew': autoRenew ? 1 : 0,
      'type': type.index,
      'totalDurationDays': totalDurationDays,
      'cycleDays': cycleDays,
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
      type: map.containsKey('type') ? SubscriptionType.values[map['type']] : SubscriptionType.recurring,
      totalDurationDays: map['totalDurationDays'],
      cycleDays: map['cycleDays'],
    );
  }
}
