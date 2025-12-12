import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'subscriptions_screen.dart';
import 'settings_screen.dart';
import 'add_transaction_screen.dart';
import '../widgets/quick_add_sheet.dart';
import 'bulk_add_screen.dart';
import 'voice_add_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isFabExpanded = false;
  late AnimationController _fabAnimation;

  final List<Widget> _screens = const [
    HomeScreen(),
    StatsScreen(),
    SubscriptionsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimation = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  void _toggleFab() {
    setState(() {
      _isFabExpanded = !_isFabExpanded;
      if (_isFabExpanded) {
        _fabAnimation.forward();
      } else {
        _fabAnimation.reverse();
      }
    });
  }

  void _onFabOptionTap(String mode) {
    _toggleFab(); // Close FAB
    if (mode == 'quick') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const QuickAddSheet(),
      );
    } else if (mode == 'manual') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
      );
    } else if (mode == 'bulk') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BulkAddScreen()),
      );
    } else if (mode == 'voice') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VoiceAddScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.subscriptions_outlined), selectedIcon: Icon(Icons.subscriptions), label: 'Subs'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
      floatingActionButton: _buildExpandableFab(),
    );
  }

  Widget _buildExpandableFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isFabExpanded) ...[
          _buildFabOption(
            icon: FontAwesomeIcons.bolt,
            label: 'Quick Add',
            color: Colors.amber,
            onTap: () => _onFabOptionTap('quick'),
          ),
          const SizedBox(height: 16),
          _buildFabOption(
            icon: FontAwesomeIcons.penToSquare,
            label: 'Manual Add',
            color: Colors.blue,
            onTap: () => _onFabOptionTap('manual'),
          ),
          const SizedBox(height: 16),
          _buildFabOption(
            icon: FontAwesomeIcons.boxesStacked,
            label: 'Bulk Add',
            color: Colors.purple,
            onTap: () => _onFabOptionTap('bulk'),
          ),
          const SizedBox(height: 16),
          _buildFabOption(
            icon: FontAwesomeIcons.microphone,
            label: 'Voice Add',
            color: Colors.redAccent,
            onTap: () => _onFabOptionTap('voice'),
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          onPressed: _toggleFab,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _fabAnimation,
          ),
        ),
      ],
    );
  }

  Widget _buildFabOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: onTap,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
