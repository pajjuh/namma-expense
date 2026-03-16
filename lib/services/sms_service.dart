import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/pending_sms.dart';

class SmsService {
  final SmsQuery _query = SmsQuery();

  // Keywords that indicate a debit/expense SMS
  static const List<String> _debitKeywords = [
    'debited',
    'deducted',
    'spent',
    'withdrawn',
    'purchase',
    'payment of',
    'paid rs',
    'sent rs',
    'txn of rs',
    'debit of rs',
    'debit rs',
    'tx #',
    'dr rs',
    'upi-',
  ];

  // Keywords to EXCLUDE (credits, OTPs, promos)
  static const List<String> _excludeKeywords = [
    'credited',
    'received',
    'otp',
    'refund',
    'cashback',
    'reward',
  ];

  /// Request SMS permission. Returns true if granted.
  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Check if SMS permission is already granted.
  Future<bool> hasPermission() async {
    return await Permission.sms.isGranted;
  }

  /// Fetch and parse debit SMS between [fromDate] and [toDate].
  Future<List<PendingSmsEntry>> fetchDebitSms(DateTime fromDate, DateTime toDate) async {
    final hasAccess = await hasPermission();
    if (!hasAccess) return [];

    List<SmsMessage> messages = [];
    try {
      messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox],
      );
    } catch (e) {
      // If SMS query fails (e.g., on iOS), return empty
      return [];
    }

    final now = DateTime.now();
    final List<PendingSmsEntry> results = [];

    // Normalize dates to start/end of day
    final startOfFrom = DateTime(fromDate.year, fromDate.month, fromDate.day);
    final endOfTo = DateTime(toDate.year, toDate.month, toDate.day, 23, 59, 59);

    for (final msg in messages) {
      final msgDate = msg.date;
      if (msgDate == null) continue;

      // Filter by date range
      if (msgDate.isBefore(startOfFrom) || msgDate.isAfter(endOfTo)) continue;

      final body = (msg.body ?? '').toLowerCase();

      // Skip excluded messages
      if (_excludeKeywords.any((kw) => body.contains(kw))) continue;

      // Check if it's a debit SMS
      if (!_debitKeywords.any((kw) => body.contains(kw))) continue;

      // Parse amount
      final amount = _parseAmount(msg.body ?? '');
      if (amount == null || amount <= 0) continue;

      // Extract sender name
      final sender = _cleanSender(msg.sender ?? 'Unknown');

      results.add(PendingSmsEntry(
        amount: amount,
        sender: sender,
        smsBody: msg.body ?? '',
        smsDate: msgDate,
        fetchedOn: now,
      ));
    }

    return results;
  }

  /// Parse amount from SMS body using multiple regex patterns.
  double? _parseAmount(String body) {
    // Common Indian banking SMS amount patterns:
    // "Rs.500.00", "Rs 500", "INR 500.00", "Rs.1,500.00", "₹500"
    final patterns = [
      RegExp(r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(?:amount|amt)\s*(?:of\s+)?(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
      RegExp(r'(?:debited|deducted|spent|withdrawn)\s+(?:by\s+)?(?:rs\.?|inr|₹)?\s*([\d,]+(?:\.\d{1,2})?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '');
        if (amountStr != null) {
          final amount = double.tryParse(amountStr);
          if (amount != null && amount > 0) return amount;
        }
      }
    }
    return null;
  }

  /// Clean sender ID to show a readable bank name
  String _cleanSender(String sender) {
    // Remove common prefixes like "AD-", "VM-", "BZ-"
    final cleaned = sender.replaceAll(RegExp(r'^[A-Z]{2}-'), '');
    return cleaned.isNotEmpty ? cleaned : sender;
  }
}
