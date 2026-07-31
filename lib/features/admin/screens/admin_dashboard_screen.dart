import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import 'admin_home_tab.dart';
import 'admin_users_screen.dart';
import 'admin_leads_screen.dart';
import 'admin_settings_screen.dart';
import '../../../shared/widgets/common_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      screen: const AdminHomeTab(),
    ),
    _NavItem(
      icon: Icons.people_rounded,
      label: 'Users',
      screen: const AdminUsersScreen(),
    ),
    _NavItem(
      icon: Icons.contacts_rounded,
      label: 'Leads',
      screen: const AdminLeadsScreen(),
    ),
    _NavItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      screen: const AdminSettingsScreen(),
    ),
  ];

  Future<void> _logout() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Sign Out',
      content: 'Are you sure you want to sign out?',
      confirmText: 'Sign Out',
      confirmColor: AppTheme.primaryBlue,
    );
    if (confirmed && mounted) {
      await context.read<AppProvider>().logout();
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_currentIndex].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _logout,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white.withOpacity(0.25),
                child: Text(
                  (user?.name.isNotEmpty == true)
                      ? user!.name[0].toUpperCase()
                      : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      body: IndexedStack(
        index: _currentIndex,
        children: _navItems.map((e) => e.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.dividerColor)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppTheme.primaryBlue.withOpacity(0.12),
          destinations: _navItems.map((item) {
            return NavigationDestination(
              icon: Icon(item.icon, color: AppTheme.textSecondary),
              selectedIcon: Icon(item.icon, color: AppTheme.primaryBlue),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Widget screen;
  const _NavItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}
