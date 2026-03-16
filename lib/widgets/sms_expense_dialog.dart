import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/sms_provider.dart';
import '../providers/expense_provider.dart';
import '../models/pending_sms.dart';
import '../models/transaction.dart';
import '../helpers/constants.dart';

class SmsExpenseDialog extends StatelessWidget {
  const SmsExpenseDialog({super.key});

  /// Show the initial prompt dialog
  static Future<void> show(BuildContext context) async {
    final smsProvider = Provider.of<SmsProvider>(context, listen: false);
    if (!smsProvider.hasPendingEntries) return;

    final count = smsProvider.pendingEntries.length;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.sms_outlined, color: Colors.deepPurple, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Missed Expenses?', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'We found $count debit transaction${count > 1 ? 's' : ''} from your SMS that you may have forgotten to add.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '⏳ These suggestions expire in 3 days',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Ignore',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey),
              ),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.checklist, size: 18),
              label: const Text('Review & Add'),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      // Show the detail list
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => const _SmsEntryListSheet(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _SmsEntryListSheet extends StatefulWidget {
  const _SmsEntryListSheet();

  @override
  State<_SmsEntryListSheet> createState() => _SmsEntryListSheetState();
}

class _SmsEntryListSheetState extends State<_SmsEntryListSheet> {
  @override
  Widget build(BuildContext context) {
    final smsProvider = Provider.of<SmsProvider>(context);
    final entries = smsProvider.pendingEntries;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.75),
      padding: EdgeInsets.only(
        top: screenHeight * 0.02,
        bottom: MediaQuery.of(context).viewInsets.bottom + screenHeight * 0.02,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
            child: Row(
              children: [
                const Icon(Icons.sms, color: Colors.deepPurple),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SMS Debit Transactions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '${entries.length} found',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // Entries list
          if (entries.isEmpty)
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.08),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: Colors.green.shade400),
                  const SizedBox(height: 12),
                  const Text('All done! No pending entries.', style: TextStyle(fontSize: 15)),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: 8,
                ),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final entry = entries[index];
                  return _buildEntryTile(entry, screenWidth, isDark);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(PendingSmsEntry entry, double screenWidth, bool isDark) {
    final dateStr = DateFormat('MMM d, h:mm a').format(entry.smsDate);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Expiry ring indicator
          _ExpiryRing(progress: entry.expiryProgress, daysLeft: entry.daysRemaining),
          SizedBox(width: screenWidth * 0.03),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${entry.amount.toStringAsFixed(entry.amount == entry.amount.roundToDouble() ? 0 : 2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.042,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.sender,
                  style: TextStyle(
                    fontSize: screenWidth * 0.032,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: screenWidth * 0.028,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Reject button
          IconButton(
            onPressed: () {
              Provider.of<SmsProvider>(context, listen: false).removeEntry(entry.id);
            },
            icon: Icon(
              Icons.close_rounded,
              color: Colors.red.shade400,
              size: screenWidth * 0.06,
            ),
            tooltip: 'Skip',
          ),

          // Accept button
          IconButton(
            onPressed: () => _acceptEntry(entry),
            icon: Icon(
              Icons.check_circle,
              color: Colors.green.shade500,
              size: screenWidth * 0.07,
            ),
            tooltip: 'Add as Expense',
          ),
        ],
      ),
    );
  }

  void _acceptEntry(PendingSmsEntry entry) {
    final smsProvider = Provider.of<SmsProvider>(context, listen: false);
    final expenseProvider = Provider.of<ExpenseProvider>(context, listen: false);

    final accepted = smsProvider.acceptEntry(entry.id);
    if (accepted != null) {
      // Create a transaction from this SMS entry
      final tx = Transaction(
        title: 'SMS: ${accepted.sender}',
        amount: accepted.amount,
        date: accepted.smsDate,
        categoryId: 'other',
        type: TransactionType.expense,
        mood: Mood.neutral,
        wallet: WalletType.upi,
        description: accepted.smsBody,
      );
      expenseProvider.addTransaction(tx);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ₹${accepted.amount.toStringAsFixed(0)} from ${accepted.sender}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// Small circular ring indicator showing expiry progress
class _ExpiryRing extends StatelessWidget {
  final double progress;
  final int daysLeft;

  const _ExpiryRing({required this.progress, required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    Color ringColor;
    if (daysLeft >= 3) {
      ringColor = Colors.green;
    } else if (daysLeft == 2) {
      ringColor = Colors.amber;
    } else {
      ringColor = Colors.red;
    }

    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(ringColor),
          ),
          Text(
            '${daysLeft}d',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: ringColor,
            ),
          ),
        ],
      ),
    );
  }
}
