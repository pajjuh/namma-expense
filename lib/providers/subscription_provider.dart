import 'package:flutter/material.dart';
import '../helpers/constants.dart';
import '../models/subscription.dart';
import '../helpers/db_helper.dart';

class SubscriptionProvider with ChangeNotifier {
  List<Subscription> _subscriptions = [];
  final DBHelper _dbHelper = DBHelper();

  List<Subscription> get subscriptions => _subscriptions;

  List<Subscription> get upcomingSubscriptions {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return _subscriptions.where((s) {
      DateTime targetDate = s.nextRenewalDate;
      if (s.type == SubscriptionType.prepaidRecharge && s.totalDurationDays != null) {
        targetDate = s.nextRenewalDate.add(Duration(days: s.totalDurationDays!));
      }
      return targetDate.isBefore(nextWeek) && targetDate.isAfter(now.subtract(const Duration(days: 30)));
    }).toList();
  }

  double get monthlyTotal {
    double total = 0;
    for (var sub in _subscriptions) {
      if (sub.type == SubscriptionType.prepaidRecharge && sub.totalDurationDays != null && sub.totalDurationDays! > 0) {
        total += sub.amount / (sub.totalDurationDays! / 30);
      } else {
        if (sub.cycle == SubscriptionCycle.monthly) {
          total += sub.amount;
        } else if (sub.cycle == SubscriptionCycle.yearly) {
          total += sub.amount / 12; // Yearly divided by 12
        } else if (sub.cycle == SubscriptionCycle.quarterly) {
          total += sub.amount / 3;  // 3 months
        } else if (sub.cycle == SubscriptionCycle.halfYearly) {
          total += sub.amount / 6;  // 6 months
        }
      }
    }
    return total;
  }

  Future<void> fetchSubscriptions() async {
    _subscriptions = await _dbHelper.getSubscriptions();
    notifyListeners();
  }

  Future<void> addSubscription(Subscription sub) async {
    await _dbHelper.insertSubscription(sub);
    await fetchSubscriptions();
  }

  Future<void> deleteSubscription(String id) async {
    await _dbHelper.deleteSubscription(id);
    await fetchSubscriptions();
  }
}
