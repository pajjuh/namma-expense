import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_provider.dart';
import '../models/subscription.dart';

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

  void _showAddDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 30));
    SubscriptionCycle selectedCycle = SubscriptionCycle.monthly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final screenHeight = MediaQuery.of(ctx).size.height;
        
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(maxHeight: screenHeight * 0.6),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: screenWidth * 0.04,
                    right: screenWidth * 0.04,
                    top: screenHeight * 0.02,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Add Subscription', style: Theme.of(context).textTheme.titleLarge),
                      SizedBox(height: screenHeight * 0.02),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Name (e.g. Netflix, Gym)',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenHeight * 0.015,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '${Provider.of<UserProvider>(context, listen: false).currency} ',
                          border: const OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.03,
                            vertical: screenHeight * 0.015,
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<SubscriptionCycle>(
                              value: selectedCycle,
                              decoration: InputDecoration(
                                labelText: 'Cycle', 
                                border: const OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.03,
                                  vertical: screenHeight * 0.012,
                                ),
                              ),
                              items: SubscriptionCycle.values.map((c) {
                                return DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()));
                              }).toList(),
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
                                if (picked != null) {
                                  setModalState(() => selectedDate = picked);
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Next Due', 
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.03,
                                    vertical: screenHeight * 0.012,
                                  ),
                                ),
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
                              title: titleController.text,
                              amount: double.parse(amountController.text),
                              nextRenewalDate: selectedDate,
                              cycle: selectedCycle,
                            );
                            Provider.of<SubscriptionProvider>(context, listen: false).addSubscription(sub);
                            Navigator.pop(context);
                          }
                        },
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
                        ),
                        child: const Text('Add Subscription'),
                      ),
                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
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
            onPressed: _showAddDialog,
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
                    color: Colors.grey,
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  const Text('No subscriptions yet'),
                  SizedBox(height: screenHeight * 0.01),
                  FilledButton.icon(
                    onPressed: _showAddDialog,
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
      onDismissed: (_) {
        Provider.of<SubscriptionProvider>(context, listen: false).deleteSubscription(sub.id);
      },
      child: Card(
        color: isUpcoming ? Colors.amber.shade50 : null,
        margin: EdgeInsets.only(bottom: screenWidth * 0.02),
        child: ListTile(
          leading: CircleAvatar(
            radius: screenWidth * 0.05,
            backgroundColor: isUpcoming ? Colors.amber : Colors.grey.shade300,
            child: Icon(
              Icons.repeat, 
              color: isUpcoming ? Colors.white : Colors.black54,
              size: screenWidth * 0.05,
            ),
          ),
          title: Text(sub.title, overflow: TextOverflow.ellipsis),
          subtitle: Text('${sub.cycle.name} • Due: ${DateFormat.yMMMd().format(sub.nextRenewalDate)}'),
          trailing: Text(
            '$currency${sub.amount.toStringAsFixed(0)}', 
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
