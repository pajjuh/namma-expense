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
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Add Subscription', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Name (e.g. Netflix, Gym)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '${Provider.of<UserProvider>(context, listen: false).currency} ',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<SubscriptionCycle>(
                          value: selectedCycle,
                          decoration: const InputDecoration(labelText: 'Cycle', border: OutlineInputBorder()),
                          items: SubscriptionCycle.values.map((c) {
                            return DropdownMenuItem(value: c, child: Text(c.name.toUpperCase()));
                          }).toList(),
                          onChanged: (val) => setModalState(() => selectedCycle = val!),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                            decoration: const InputDecoration(labelText: 'Next Due', border: OutlineInputBorder()),
                            child: Text(DateFormat.yMMMd().format(selectedDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
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
                    child: const Text('Add Subscription'),
                  ),
                  const SizedBox(height: 24),
                ],
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
                  const Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No subscriptions yet'),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _showAddDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Monthly Total Card
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Fixed Cost', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '$currency ${subProvider.monthlyTotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Upcoming
                if (subProvider.upcomingSubscriptions.isNotEmpty) ...[
                  Text('Upcoming Renewals', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...subProvider.upcomingSubscriptions.map((sub) => _buildSubTile(sub, currency, isUpcoming: true)),
                  const SizedBox(height: 16),
                ],

                // All
                Text('All Subscriptions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...subProvider.subscriptions.map((sub) => _buildSubTile(sub, currency)),
              ],
            ),
    );
  }

  Widget _buildSubTile(Subscription sub, String currency, {bool isUpcoming = false}) {
    return Dismissible(
      key: Key(sub.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        Provider.of<SubscriptionProvider>(context, listen: false).deleteSubscription(sub.id);
      },
      child: Card(
        color: isUpcoming ? Colors.amber.shade50 : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isUpcoming ? Colors.amber : Colors.grey.shade300,
            child: Icon(Icons.repeat, color: isUpcoming ? Colors.white : Colors.black54),
          ),
          title: Text(sub.title),
          subtitle: Text('${sub.cycle.name} • Due: ${DateFormat.yMMMd().format(sub.nextRenewalDate)}'),
          trailing: Text('$currency${sub.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
