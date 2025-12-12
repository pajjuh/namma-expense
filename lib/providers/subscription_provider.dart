import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../helpers/db_helper.dart';

class SubscriptionProvider with ChangeNotifier {
  List<Subscription> _subscriptions = [];
  final DBHelper _dbHelper = DBHelper();

  List<Subscription> get subscriptions => _subscriptions;

  List<Subscription> get upcomingSubscriptions {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return _subscriptions.where((s) => s.nextRenewalDate.isBefore(nextWeek)).toList();
  }

  double get monthlyTotal {
    double total = 0;
    for (var sub in _subscriptions) {
      if (sub.cycle == SubscriptionCycle.monthly) {
        total += sub.amount;
      } else {
        total += sub.amount / 12; // Yearly divided by 12
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
