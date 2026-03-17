import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';
import '../services/backup_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _limitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final limit = Provider.of<UserProvider>(context, listen: false).dailyLimit;
      _limitController.text = limit > 0 ? limit.toStringAsFixed(0) : '';
    });
  }

  void _saveDailyLimit() {
    final val = double.tryParse(_limitController.text) ?? 0.0;
    Provider.of<UserProvider>(context, listen: false).setDailyLimit(val);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Daily limit saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        children: [
          // Profile Info
          Card(
            child: ListTile(
              leading: CircleAvatar(
                radius: screenWidth * 0.05,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  userProvider.userName.isNotEmpty ? userProvider.userName[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: screenWidth * 0.045),
                ),
              ),
              title: Text(
                userProvider.userName,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('Mode: ${userProvider.userMode.name.toUpperCase()}'),
            ),
          ),
          SizedBox(height: screenHeight * 0.03),

          // Theme Toggle
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: screenHeight * 0.01),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            secondary: const Icon(Icons.dark_mode),
            value: userProvider.isDarkTheme,
            onChanged: (val) => userProvider.toggleTheme(val),
          ),
          const Divider(),

          // Daily Limit
          SizedBox(height: screenHeight * 0.02),
          Text('Budget', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: screenHeight * 0.01),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Daily Spending Limit',
                    prefixText: '${userProvider.currency} ',
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03,
                      vertical: screenHeight * 0.015,
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              FilledButton(
                onPressed: _saveDailyLimit,
                child: const Text('Save'),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'You will see a warning when you exceed this limit.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SwitchListTile(
            title: const Text('Exclude Subscriptions & Recharges'),
            subtitle: const Text('Do not let recurring/generated bills trip the daily limit warning.'),
            value: userProvider.excludeSubsFromDailyLimit,
            onChanged: (val) => userProvider.toggleExcludeSubs(val),
            contentPadding: EdgeInsets.zero,
          ),
          Divider(height: screenHeight * 0.04),

          // Mode Switch
          Text('User Mode', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: screenHeight * 0.01),
          ...UserMode.values.map((mode) {
            IconData icon;
            switch (mode) {
              case UserMode.student:
                icon = FontAwesomeIcons.graduationCap;
                break;
              case UserMode.professional:
                icon = FontAwesomeIcons.briefcase;
                break;
              case UserMode.homemaker:
                icon = FontAwesomeIcons.houseUser;
                break;
            }

            return RadioListTile<UserMode>(
              title: Text(mode.name[0].toUpperCase() + mode.name.substring(1)),
              secondary: Icon(icon, size: screenWidth * 0.05),
              value: mode,
              groupValue: userProvider.userMode,
              onChanged: (val) {
                if (val != null) {
                  userProvider.saveUser(
                    userProvider.userName,
                    userProvider.currency,
                    val,
                  );
                }
              },
            );
          }),
          Divider(height: screenHeight * 0.04),

          // Data & Backup
          Text('Data & Backup', style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: screenHeight * 0.01),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.upload, color: Colors.white),
                  ),
                  title: const Text('Export Backup'),
                  subtitle: const Text('Save your data to a JSON file'),
                  onTap: () => BackupService.exportData(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orangeAccent,
                    child: Icon(Icons.download, color: Colors.white),
                  ),
                  title: const Text('Import Backup'),
                  subtitle: const Text('Restore data from a JSON file'),
                  onTap: () => BackupService.importData(context),
                ),
              ],
            ),
          ),
          Divider(height: screenHeight * 0.04),

          // About / Version
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About NammaExpense'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Row(
                    children: [
                      Image.asset('assets/applogo.jpg', width: screenWidth * 0.1, height: screenWidth * 0.1),
                      SizedBox(width: screenWidth * 0.03),
                      const Expanded(child: Text('NammaExpense v1.0.0', style: TextStyle(fontSize: 18))),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Your money, your rules.'),
                      SizedBox(height: screenHeight * 0.02),
                      const Divider(),
                      SizedBox(height: screenHeight * 0.01),
                      const Text('Created by', style: TextStyle(color: Colors.grey)),
                      const Text('Prajwal Suresh Hasilakar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: screenHeight * 0.02),
                      const Text('Heeeyyy mate follow me 👋'),
                      SizedBox(height: screenHeight * 0.02),
                      FilledButton.icon(
                        onPressed: () async {
                          final Uri url = Uri.parse('https://www.instagram.com/pajju.ig');
                          try {
                            bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
                            if (!launched) {
                              await launchUrl(url, mode: LaunchMode.inAppBrowserView);
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Could not launch Instagram. Make sure to full Restart the app!')),
                              );
                            }
                          }
                        },
                        icon: const Icon(FontAwesomeIcons.instagram),
                        label: const Text('Instagram'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE1306C), // Insta color
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
