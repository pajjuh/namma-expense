import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../providers/subscription_provider.dart';
import '../providers/expense_provider.dart';
import '../providers/user_provider.dart';
import '../models/subscription.dart';
import '../models/transaction.dart' as txn;
import '../helpers/constants.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch subs on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubscriptionProvider>(context, listen: false).fetchSubscriptions();
    });
  }

  void _showAddEditDialog({Subscription? existingSub}) {
    final isEditing = existingSub != null;
    final titleController = TextEditingController(text: existingSub?.title ?? '');
    final amountController = TextEditingController(text: existingSub?.amount.toStringAsFixed(0) ?? '');
    final daysController = TextEditingController(text: existingSub?.totalDurationDays?.toString() ?? '');
    
    DateTime selectedDate = existingSub?.nextRenewalDate ?? DateTime.now();
    SubscriptionCycle selectedCycle = existingSub?.cycle ?? SubscriptionCycle.monthly;
    
    DateTime? rechargeStartDate = existingSub?.type == SubscriptionType.prepaidRecharge ? existingSub?.nextRenewalDate : null;
    DateTime? rechargeEndDate = existingSub?.type == SubscriptionType.prepaidRecharge && existingSub?.totalDurationDays != null 
        ? existingSub!.nextRenewalDate.add(Duration(days: existingSub.totalDurationDays!)) : null; // Expiry
        
    int selectedCycleDays = existingSub?.cycleDays ?? 28;
    bool anchorIsEndDate = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final screenHeight = MediaQuery.of(ctx).size.height;
        final currency = Provider.of<UserProvider>(context, listen: false).currency;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return DefaultTabController(
              length: 2,
              child: Container(
                constraints: BoxConstraints(maxHeight: screenHeight * 0.8),
                margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: isEditing && existingSub?.type == SubscriptionType.recurring ? 'Edit Subscription' : (isEditing ? 'Subscription' : 'Subscription')),
                        Tab(text: isEditing && existingSub?.type == SubscriptionType.prepaidRecharge ? 'Edit Recharge' : (isEditing ? 'Recharge Plan' : 'Recharge Plan')),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // TAB 1: Subscription
                          SingleChildScrollView(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: titleController,
                                  decoration: const InputDecoration(labelText: 'Name (e.g. Netflix, Gym)', border: OutlineInputBorder(), isDense: true),
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                TextField(
                                  controller: amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(labelText: 'Amount', prefixText: '$currency ', border: const OutlineInputBorder(), isDense: true),
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<SubscriptionCycle>(
                                        isExpanded: true,
                                        value: selectedCycle,
                                        decoration: const InputDecoration(labelText: 'Cycle', border: OutlineInputBorder(), isDense: true),
                                        items: SubscriptionCycle.values.map((c) => DropdownMenuItem(value: c, child: Text(c.displayName, overflow: TextOverflow.ellipsis))).toList(),
                                        onChanged: (val) => setModalState(() => selectedCycle = val!),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: selectedDate,
                                            firstDate: DateTime.now(),
                                            lastDate: DateTime.now().add(const Duration(days: 365)),
                                          );
                                          if (picked != null) setModalState(() => selectedDate = picked);
                                        },
                                        child: InputDecorator(
                                          decoration: const InputDecoration(labelText: 'Next Due', border: OutlineInputBorder(), isDense: true),
                                          child: Text(DateFormat.yMMMd().format(selectedDate)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                FilledButton(
                                  onPressed: () {
                                    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                                      final sub = Subscription(
                                        id: existingSub?.id,
                                        title: titleController.text,
                                        amount: double.parse(amountController.text),
                                        nextRenewalDate: selectedDate,
                                        cycle: selectedCycle,
                                        type: SubscriptionType.recurring,
                                      );
                                      Provider.of<SubscriptionProvider>(context, listen: false).addSubscription(sub);
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Text(isEditing ? 'Save Changes' : 'Add Subscription'),
                                ),
                              ],
                            ),
                          ),
                          
                          // TAB 2: Recharge
                          SingleChildScrollView(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: titleController,
                                  decoration: const InputDecoration(labelText: 'Plan Name (e.g. Airtel 84 Days)', border: OutlineInputBorder(), isDense: true),
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: amountController,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(labelText: 'Total Bill Amount', prefixText: '$currency ', border: const OutlineInputBorder(), isDense: true),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Expanded(
                                      child: TextField(
                                        controller: daysController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(labelText: 'Total Days', border: OutlineInputBorder(), isDense: true),
                                        onChanged: (val) {
                                          int days = int.tryParse(val) ?? 0;
                                          if (days > 0) {
                                            setModalState(() {
                                              if (anchorIsEndDate && rechargeEndDate != null) {
                                                rechargeStartDate = rechargeEndDate!.subtract(Duration(days: days));
                                              } else if (!anchorIsEndDate && rechargeStartDate != null) {
                                                rechargeEndDate = rechargeStartDate!.add(Duration(days: days));
                                              }
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: rechargeStartDate ?? DateTime.now(),
                                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                            lastDate: DateTime.now().add(const Duration(days: 365)),
                                          );
                                          if (picked != null) {
                                            setModalState(() {
                                              rechargeStartDate = picked;
                                              anchorIsEndDate = false;
                                              int days = int.tryParse(daysController.text) ?? 0;
                                              if (days > 0) {
                                                rechargeEndDate = rechargeStartDate!.add(Duration(days: days));
                                              } else if (rechargeEndDate != null) {
                                                int diff = rechargeEndDate!.difference(rechargeStartDate!).inDays;
                                                daysController.text = diff > 0 ? diff.toString() : '';
                                              }
                                            });
                                          }
                                        },
                                        child: InputDecorator(
                                          decoration: const InputDecoration(labelText: 'Start Date', border: OutlineInputBorder(), isDense: true),
                                          child: Text(rechargeStartDate != null ? DateFormat.yMMMd().format(rechargeStartDate!) : 'Select'),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: screenWidth * 0.03),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: rechargeEndDate ?? (rechargeStartDate?.add(const Duration(days: 28)) ?? DateTime.now()),
                                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                            lastDate: DateTime.now().add(const Duration(days: 365)),
                                          );
                                          if (picked != null) {
                                            setModalState(() {
                                              rechargeEndDate = picked;
                                              anchorIsEndDate = true;
                                              if (rechargeStartDate != null) {
                                                int diff = rechargeEndDate!.difference(rechargeStartDate!).inDays;
                                                daysController.text = diff > 0 ? diff.toString() : '';
                                              } else {
                                                int days = int.tryParse(daysController.text) ?? 0;
                                                if (days > 0) {
                                                  rechargeStartDate = rechargeEndDate!.subtract(Duration(days: days));
                                                }
                                              }
                                            });
                                          }
                                        },
                                        child: InputDecorator(
                                          decoration: const InputDecoration(labelText: 'End Date', border: OutlineInputBorder(), isDense: true),
                                          child: Text(rechargeEndDate != null ? DateFormat.yMMMd().format(rechargeEndDate!) : 'Select'),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: screenHeight * 0.015),
                                DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  value: selectedCycleDays,
                                  decoration: const InputDecoration(labelText: '1 Month =', border: OutlineInputBorder(), isDense: true),
                                  items: [20, 24, 28, 30].map((int value) {
                                    return DropdownMenuItem<int>(
                                      value: value,
                                      child: Text('$value Days', overflow: TextOverflow.ellipsis),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setModalState(() {
                                        selectedCycleDays = val;
                                        if (val == 28 || val == 30) selectedCycle = SubscriptionCycle.monthly;
                                      });
                                    }
                                  },
                                ),
                                SizedBox(height: screenHeight * 0.02),
                                OutlinedButton(
                                  onPressed: () {
                                    if (amountController.text.isEmpty || daysController.text.isEmpty || rechargeStartDate == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and select dates')));
                                      return;
                                    }
                                    double totalAmount = double.parse(amountController.text);
                                    int totalDays = int.parse(daysController.text);
                                    int chunks = (totalDays / selectedCycleDays).ceil();
                                    double amtPerChunk = totalAmount / chunks;
                                    
                                    showDialog(context: context, builder: (c) => AlertDialog(
                                      title: const Text('Preview Plan'),
                                      content: Text('This recharge will create $chunks entries of $currency${amtPerChunk.toStringAsFixed(2)} starting from ${DateFormat.yMMMd().format(rechargeStartDate!)}.'),
                                      actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close'))],
                                    ));
                                  },
                                  child: const Text('Preview Splits'),
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                FilledButton(
                                  onPressed: () {
                                    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty && daysController.text.isNotEmpty && rechargeStartDate != null) {
                                      double totalAmount = double.parse(amountController.text);
                                      int totalDays = int.parse(daysController.text);
                                      int chunks = (totalDays / selectedCycleDays).ceil();
                                      double amtPerChunk = totalAmount / chunks;
                                      
                                      String groupId = existingSub?.id ?? const Uuid().v4();
                                      
                                      // Save Parent Record
                                      final sub = Subscription(
                                        id: groupId,
                                        title: titleController.text,
                                        amount: totalAmount,
                                        nextRenewalDate: rechargeStartDate!, // Start date essentially
                                        cycle: SubscriptionCycle.monthly, // generic mapping
                                        type: SubscriptionType.prepaidRecharge,
                                        totalDurationDays: totalDays,
                                        cycleDays: selectedCycleDays,
                                      );
                                      Provider.of<SubscriptionProvider>(context, listen: false).addSubscription(sub);
                                      
                                      // If editing, clear old generated split transactions first
                                      final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);
                                      if (isEditing) {
                                        expenseProvider.deleteTransactionGroup(groupId);
                                      }
                                      
                                      // Save Split Transactions
                                      for (int i = 0; i < chunks; i++) {
                                        DateTime entryDate = rechargeStartDate!.add(Duration(days: i * selectedCycleDays));
                                        final t = txn.Transaction(
                                          title: titleController.text,
                                          amount: amtPerChunk,
                                          date: entryDate,
                                          categoryId: 'recharge', // Generic category
                                          type: TransactionType.expense,
                                          origin: TransactionOrigin.rechargeSplit,
                                          linkedGroupId: groupId,
                                          description: '[Recharge split (${i+1}/$chunks)]',
                                        );
                                        expenseProvider.addTransaction(t);
                                      }
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: Text(isEditing ? 'Save Changes' : 'Save Recharge Plan'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    final currency = Provider.of<UserProvider>(context).currency;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: subProvider.subscriptions.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.subscriptions_outlined, 
                    size: screenWidth * 0.16, 
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  const Text('No subscriptions yet'),
                  SizedBox(height: screenHeight * 0.01),
                  FilledButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              children: [
                // Monthly Total Card
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: Text(
                            'Monthly Fixed Cost', 
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$currency ${subProvider.monthlyTotal.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: screenWidth * 0.05, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.02),

                // Upcoming
                if (subProvider.upcomingSubscriptions.isNotEmpty) ...[
                  Text('Upcoming Renewals', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: screenHeight * 0.01),
                  ...subProvider.upcomingSubscriptions.map((sub) => _buildSubTile(sub, currency, screenWidth, isUpcoming: true)),
                  SizedBox(height: screenHeight * 0.02),
                ],

                // All
                Text('All Subscriptions', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: screenHeight * 0.01),
                ...subProvider.subscriptions.map((sub) => _buildSubTile(sub, currency, screenWidth)),
              ],
            ),
    );
  }

  Widget _buildSubTile(Subscription sub, String currency, double screenWidth, {bool isUpcoming = false}) {
    return Dismissible(
      key: Key(sub.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: screenWidth * 0.04),
        child: Icon(Icons.delete, color: Colors.white, size: screenWidth * 0.06),
      ),
      confirmDismiss: (_) async {
        if (sub.type == SubscriptionType.prepaidRecharge) {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Delete Recharge Plan?'),
              content: const Text('This will delete the plan AND remove all of its auto-generated expenses from your dashboard. Proceed?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    Provider.of<SubscriptionProvider>(context, listen: false).deleteSubscription(sub.id);
                    Provider.of<ExpenseProvider>(context, listen: false).deleteTransactionGroup(sub.id);
                    Navigator.of(ctx).pop(true);
                  },
                  child: const Text('Delete All'),
                ),
              ],
            ),
          );
        } else {
          Provider.of<SubscriptionProvider>(context, listen: false).deleteSubscription(sub.id);
          return true;
        }
      },
      onDismissed: (_) {
        // Handled in confirmDismiss to support complex provider interactions
      },
      child: Card(
        color: isUpcoming ? Colors.amber.withOpacity(0.15) : null,
        margin: EdgeInsets.only(bottom: screenWidth * 0.02),
        child: ListTile(
          leading: CircleAvatar(
            radius: screenWidth * 0.05,
            backgroundColor: isUpcoming ? Colors.amber : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey.shade300),
            child: Icon(
              Icons.repeat, 
              color: isUpcoming ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
              size: screenWidth * 0.05,
            ),
          ),
          title: Text(sub.title, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            sub.type == SubscriptionType.prepaidRecharge 
              ? '${sub.totalDurationDays} Days Plan\nRenewal: ${_calculateNextRechargeRenewal(sub)} • Exp: ${DateFormat.yMMMd().format(sub.nextRenewalDate.add(Duration(days: sub.totalDurationDays ?? 0)))}'
              : '${sub.cycle.displayName} • Due: ${DateFormat.yMMMd().format(sub.nextRenewalDate)}'
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showAddEditDialog(existingSub: sub),
              ),
              Text(
                '$currency${sub.amount.toStringAsFixed(0)}', 
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateNextRechargeRenewal(Subscription sub) {
    if (sub.type != SubscriptionType.prepaidRecharge) return '';
    final cycle = sub.cycleDays ?? 28;
    DateTime nextDate = sub.nextRenewalDate; // Start date
    DateTime now = DateTime.now();
    DateTime exp = sub.nextRenewalDate.add(Duration(days: sub.totalDurationDays ?? 0));
    
    // Find the immediate next chunk date
    while (nextDate.isBefore(now) && nextDate.isBefore(exp)) {
      nextDate = nextDate.add(Duration(days: cycle));
    }
    
    // If we've passed expiration, next date is the expiry
    if (nextDate.isAfter(exp)) nextDate = exp;
    
    return DateFormat.yMMMd().format(nextDate);
  }
}
