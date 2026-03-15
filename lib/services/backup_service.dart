import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../helpers/db_helper.dart';
import '../models/transaction.dart' as model;
import '../models/subscription.dart';
import '../providers/expense_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_provider.dart';

class BackupService {
  static const int _backupVersion = 1;

  /// Creates a JSON backup and shares it
  static Future<void> exportData(BuildContext context) async {
    try {
      final dbHelper = DBHelper();
      final txns = await dbHelper.getTransactions();
      final subs = await dbHelper.getSubscriptions();
      
      if (!context.mounted) return;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final settings = userProvider.exportSettings();

      // Ensure we run heavy JSON encoding in an isolate 
      final String jsonString = await compute(_encodeBackupData, {
        'backup_version': _backupVersion,
        'transactions': txns.map((t) => t.toMap()).toList(),
        'subscriptions': subs.map((s) => s.toMap()).toList(),
        'settings': settings,
      });

      // Write to a temporary file
      final directory = await getApplicationDocumentsDirectory();
      final dateStr = DateFormat('yyyy_MM_dd').format(DateTime.now());
      final file = File('${directory.path}/nammaexpense_backup_$dateStr.json');
      await file.writeAsString(jsonString);

      // Share the file
      final xFile = XFile(file.path);
      await Share.shareXFiles(
        [xFile], 
        text: 'NammaExpense Backup - $dateStr',
      );
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  /// Picker and import workflow
  static Future<void> importData(BuildContext context) async {
    try {
      // 1. Pick File
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.single.path == null) return; // User canceled

      if (!context.mounted) return;

      // 2. Read and Validate
      final file = File(result.files.single.path!);
      final fileContent = await file.readAsString();

      // Show immediate loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Validating backup...'),
              ],
            ),
          ),
        ),
      );

      // Parse in isolate
      final parsedData = await compute(_decodeBackupData, fileContent);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close validation dialog

      // Validate structure and version
      if (!parsedData.containsKey('backup_version') || parsedData['backup_version'] != _backupVersion) {
        throw Exception("Unsupported backup version");
      }
      if (!parsedData.containsKey('transactions') || !parsedData.containsKey('subscriptions') || !parsedData.containsKey('settings')) {
        throw Exception("Invalid backup file structure");
      }

      // 3. Confirm Import
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Restore Backup'),
            ],
          ),
          content: const Text(
            'This will erase all current data and replace it with the backup data.\n\nDo you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Yes, Erase & Restore'),
            ),
          ],
        ),
      );

      if (confirm != true || !context.mounted) return;

      // Show restoring indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Restoring data...'),
              ],
            ),
          ),
        ),
      );

      // 4. Perform Restore
      final dbHelper = DBHelper();
      
      // Parse mappings back to models
      final List<dynamic> txListStr = parsedData['transactions'];
      final List<dynamic> subListStr = parsedData['subscriptions'];
      final Map<String, dynamic> settingsData = parsedData['settings'];

      final txns = txListStr.map((e) => model.Transaction.fromMap(e as Map<String, dynamic>)).toList();
      final subs = subListStr.map((e) => Subscription.fromMap(e as Map<String, dynamic>)).toList();

      // Database clear and insert
      await dbHelper.clearAllData();
      await dbHelper.insertTransactionsBatch(txns);
      await dbHelper.insertSubscriptionsBatch(subs);

      if (!context.mounted) return;
      
      // SharedPreferences update
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.importSettings(settingsData);

      // Refresh providers
      await Provider.of<ExpenseProvider>(context, listen: false).fetchTransactions();
      await Provider.of<SubscriptionProvider>(context, listen: false).fetchSubscriptions();

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close restoring dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup restored successfully!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close any loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper methods for compute (Must be top-level or static)
  static String _encodeBackupData(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  static Map<String, dynamic> _decodeBackupData(String jsonStr) {
    return jsonDecode(jsonStr);
  }
}
