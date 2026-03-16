import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class PendingSmsEntry {
  final String id;
  final double amount;
  final String sender;
  final String smsBody;
  final DateTime smsDate;
  final DateTime fetchedOn;
  final DateTime expiresOn;

  PendingSmsEntry({
    String? id,
    required this.amount,
    required this.sender,
    required this.smsBody,
    required this.smsDate,
    required this.fetchedOn,
    DateTime? expiresOn,
  })  : id = id ?? _uuid.v4(),
        expiresOn = expiresOn ?? fetchedOn.add(const Duration(days: 3));

  bool get isExpired => DateTime.now().isAfter(expiresOn);

  /// Days remaining before auto-expiry (0, 1, 2, or 3)
  int get daysRemaining {
    final diff = expiresOn.difference(DateTime.now()).inDays;
    return diff.clamp(0, 3);
  }

  /// Progress from 0.0 (expired) to 1.0 (just fetched)
  double get expiryProgress {
    final total = expiresOn.difference(fetchedOn).inSeconds;
    final remaining = expiresOn.difference(DateTime.now()).inSeconds;
    if (total <= 0) return 0.0;
    return (remaining / total).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'sender': sender,
        'smsBody': smsBody,
        'smsDate': smsDate.toIso8601String(),
        'fetchedOn': fetchedOn.toIso8601String(),
        'expiresOn': expiresOn.toIso8601String(),
      };

  factory PendingSmsEntry.fromJson(Map<String, dynamic> json) {
    return PendingSmsEntry(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      sender: json['sender'] ?? '',
      smsBody: json['smsBody'] ?? '',
      smsDate: DateTime.parse(json['smsDate']),
      fetchedOn: DateTime.parse(json['fetchedOn']),
      expiresOn: DateTime.parse(json['expiresOn']),
    );
  }
}
