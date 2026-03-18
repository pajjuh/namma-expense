import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const String _versionJsonUrl =
    'https://raw.githubusercontent.com/pajjuh/namma-expense/main/version.json';

Future<void> checkForUpdate(BuildContext context) async {
  try {
    final response = await http
        .get(Uri.parse(_versionJsonUrl))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) return;

    final data = jsonDecode(response.body);

    final String latestVersion = data['latest_version'];
    final String minVersion = data['min_version'];
    final String apkUrl = data['apk_url'];

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    final currentV = Version.parse(currentVersion);
    final latestV = Version.parse(latestVersion);
    final minV = Version.parse(minVersion);

    final prefs = await SharedPreferences.getInstance();
    final skippedVersion = prefs.getString('skipped_version');

    // Force update — current version is below minimum
    if (currentV < minV) {
      if (!context.mounted) return;
      _showUpdateDialog(context, apkUrl, latestVersion, force: true);
      return;
    }

    // Optional update — newer version available
    if (currentV < latestV) {
      if (skippedVersion == latestVersion) return; // user chose to skip this
      if (!context.mounted) return;
      _showUpdateDialog(context, apkUrl, latestVersion, force: false);
    }
  } catch (_) {
    // Silently fail — no internet or bad JSON should not crash the app
  }
}

void _showUpdateDialog(
  BuildContext context,
  String apkUrl,
  String latestVersion, {
  bool force = false,
}) {
  showDialog(
    context: context,
    barrierDismissible: !force,
    builder: (ctx) => PopScope(
      canPop: !force,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          force ? 'Update Required ⚠️' : 'Update Available 🚀',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          force
              ? 'A critical update (v$latestVersion) is required to continue using NammaExpense. Please update now.'
              : 'Version $latestVersion is available! Update for the latest features and fixes.',
        ),
        actions: [
          if (!force)
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('skipped_version', latestVersion);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Remind Me Later'),
            ),
          FilledButton.icon(
            icon: const Icon(Icons.system_update_alt),
            label: const Text('Update Now'),
            onPressed: () async {
              final uri = Uri.parse(apkUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
    ),
  );
}
