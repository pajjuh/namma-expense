import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/user_provider.dart';
import '../helpers/constants.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Info
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(userProvider.userName.isNotEmpty ? userProvider.userName[0].toUpperCase() : '?'),
              ),
              title: Text(userProvider.userName),
              subtitle: Text('Mode: ${userProvider.userMode.name.toUpperCase()}'),
            ),
          ),
          const SizedBox(height: 24),

          // Theme Toggle
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme'),
            secondary: const Icon(Icons.dark_mode),
            value: userProvider.isDarkTheme,
            onChanged: (val) => userProvider.toggleTheme(val),
          ),
          const Divider(),

          // Daily Limit
          const SizedBox(height: 16),
          Text('Budget', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
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
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _saveDailyLimit,
                child: const Text('Save'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You will see a warning when you exceed this limit.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 32),

          // Mode Switch
          Text('User Mode', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
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
              secondary: Icon(icon),
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
          const Divider(height: 32),

          // About / Version
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About NammaExpense'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'NammaExpense',
                applicationVersion: '1.0.0',
                applicationLegalese: 'Your money, your rules.',
              );
            },
          ),
        ],
      ),
    );
  }
}
