import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';
import '../services/backup_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'manage_categories_screen.dart';
import 'package:nammaexpense/l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

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
      SnackBar(content: Text(AppLocalizations.of(context)!.dailyLimitSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.settings)),
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
          Text(AppLocalizations.of(context)!.appearance, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: screenHeight * 0.01),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.darkMode),
            subtitle: Text(AppLocalizations.of(context)!.enableDarkTheme),
            secondary: const Icon(Icons.dark_mode),
            value: userProvider.isDarkTheme,
            onChanged: (val) => userProvider.toggleTheme(val),
          ),
          const Divider(),

          // Language Switch
          SizedBox(height: screenHeight * 0.02),
          Text(AppLocalizations.of(context)!.language, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: screenHeight * 0.01),
          ListTile(
            title: Text(AppLocalizations.of(context)!.language),
            leading: const Icon(Icons.language),
            trailing: DropdownButton<String>(
              value: Provider.of<LocaleProvider>(context).locale?.languageCode ?? 'en',
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'kn', child: Text('ಕನ್ನಡ')),
              ],
              onChanged: (val) {
                if (val != null) {
                  Provider.of<LocaleProvider>(context, listen: false).setLocale(Locale(val));
                }
              },
            ),
          ),
          const Divider(),

          // Daily Limit
          SizedBox(height: screenHeight * 0.02),
          Text(AppLocalizations.of(context)!.budget, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: screenHeight * 0.01),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _limitController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.dailyLimitStr,
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
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            AppLocalizations.of(context)!.dailyLimitWarningText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SwitchListTile(
            title: Text(AppLocalizations.of(context)!.excludeSubs),
            subtitle: Text(AppLocalizations.of(context)!.excludeSubsDesc),
            value: userProvider.excludeSubsFromDailyLimit,
            onChanged: (val) => userProvider.toggleExcludeSubs(val),
            contentPadding: EdgeInsets.zero,
          ),
          Divider(height: screenHeight * 0.04),

          // Manage Categories
          Text(AppLocalizations.of(context)!.preferences, style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: screenHeight * 0.01),
          ListTile(
            title: Text(AppLocalizations.of(context)!.manageCategories),
            subtitle: Text(AppLocalizations.of(context)!.manageCategoriesDesc),
            leading: const Icon(Icons.category),
            trailing: const Icon(Icons.chevron_right),
            contentPadding: EdgeInsets.zero,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageCategoriesScreen()),
              );
            },
          ),
          Divider(height: screenHeight * 0.04),
          // Mode Switch
          Text(AppLocalizations.of(context)!.userMode, style: Theme.of(context).textTheme.titleMedium),
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
            subtitle: const Text('Version 1.1.0'),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Row(
                    children: [
                      Image.asset('assets/applogo.jpg', width: screenWidth * 0.1, height: screenWidth * 0.1),
                      SizedBox(width: screenWidth * 0.03),
                      const Expanded(child: Text('NammaExpense v1.1.0', style: TextStyle(fontSize: 18))),
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
