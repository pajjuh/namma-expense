import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pending_sms.dart';
import '../services/sms_service.dart';

class SmsProvider with ChangeNotifier {
  static const String _lastOpenedKey = 'sms_last_opened_date';
  static const String _pendingEntriesKey = 'sms_pending_entries';

  final SmsService _smsService = SmsService();

  List<PendingSmsEntry> _pendingEntries = [];
  bool _hasChecked = false;

  List<PendingSmsEntry> get pendingEntries => _pendingEntries;
  bool get hasPendingEntries => _pendingEntries.isNotEmpty;
  bool get hasChecked => _hasChecked;

  /// Called on app open. Checks if we need to fetch SMS.
  Future<void> checkAndFetchSms() async {
    if (_hasChecked) return; // Only check once per app session

    final prefs = await SharedPreferences.getInstance();

    // Load any existing pending entries first
    await _loadPendingEntries(prefs);

    // Clean expired entries
    _cleanExpired();

    // Determine date range to fetch
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final lastOpenedStr = prefs.getString(_lastOpenedKey);
    DateTime fromDate;

    if (lastOpenedStr != null) {
      final lastOpened = DateTime.parse(lastOpenedStr);
      final lastOpenedDay = DateTime(lastOpened.year, lastOpened.month, lastOpened.day);

      // If we already opened today, no new SMS to fetch
      if (!lastOpenedDay.isBefore(today)) {
        _hasChecked = true;
        notifyListeners();
        return;
      }

      fromDate = lastOpenedDay;
    } else {
      // First time opening — fetch yesterday only
      fromDate = yesterday;
    }

    // Request SMS permission
    final hasPermission = await _smsService.requestPermission();
    if (!hasPermission) {
      _hasChecked = true;
      // Save today as last opened even if permission denied
      await prefs.setString(_lastOpenedKey, today.toIso8601String());
      notifyListeners();
      return;
    }

    // Fetch debit SMS from [fromDate, yesterday]
    final newEntries = await _smsService.fetchDebitSms(fromDate, yesterday);

    // Deduplicate: don't readd entries with same amount + same smsDate
    for (final entry in newEntries) {
      final isDuplicate = _pendingEntries.any(
        (existing) =>
            existing.amount == entry.amount &&
            existing.smsDate.difference(entry.smsDate).inMinutes.abs() < 2,
      );
      if (!isDuplicate) {
        _pendingEntries.add(entry);
      }
    }

    // Save state
    await _savePendingEntries(prefs);
    await prefs.setString(_lastOpenedKey, today.toIso8601String());

    _hasChecked = true;
    notifyListeners();
  }

  /// Remove a single entry (user rejected it)
  void removeEntry(String id) async {
    _pendingEntries.removeWhere((e) => e.id == id);
    final prefs = await SharedPreferences.getInstance();
    await _savePendingEntries(prefs);
    notifyListeners();
  }

  /// Accept an entry and remove it from pending. Returns the entry.
  PendingSmsEntry? acceptEntry(String id) {
    final index = _pendingEntries.indexWhere((e) => e.id == id);
    if (index == -1) return null;
    final entry = _pendingEntries.removeAt(index);
    SharedPreferences.getInstance().then((prefs) => _savePendingEntries(prefs));
    notifyListeners();
    return entry;
  }

  /// Remove all expired entries
  void _cleanExpired() {
    _pendingEntries.removeWhere((e) => e.isExpired);
  }

  /// Load pending entries from SharedPreferences
  Future<void> _loadPendingEntries(SharedPreferences prefs) async {
    final jsonStr = prefs.getString(_pendingEntriesKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        _pendingEntries = jsonList
            .map((item) => PendingSmsEntry.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        _pendingEntries = [];
      }
    }
  }

  /// Save pending entries to SharedPreferences
  Future<void> _savePendingEntries(SharedPreferences prefs) async {
    final jsonStr = jsonEncode(_pendingEntries.map((e) => e.toJson()).toList());
    await prefs.setString(_pendingEntriesKey, jsonStr);
  }

  /// Dismiss all pending entries
  void dismissAll() async {
    // Don't delete — just mark as checked so popup won't show again this session
    // Entries will auto-expire after 3 days
    _hasChecked = true;
    notifyListeners();
  }
}
