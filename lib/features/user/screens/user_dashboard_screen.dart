import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/common_widgets.dart';
import 'user_home_tab.dart';
import 'user_leads_screen.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_rounded,
      label: 'Home',
      screen: const UserHomeTab(),
    ),
    _NavItem(
      icon: Icons.contacts_rounded,
      label: 'My Leads',
      screen: const UserLeadsScreen(),
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

  Future<void> _contactAdmin() async {
    final phone = context.read<AppProvider>().settings.adminSupportPhone;
    if (phone.isEmpty) {
      AppSnackbar.error(context, 'Admin support number not configured yet.');
      return;
    }
    final cleaned = phone.replaceAll(' ', '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) AppSnackbar.error(context, 'Cannot open phone dialer.');
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
                      : 'U',
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

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _contactAdmin,
        backgroundColor: AppTheme.successColor,
        icon: const Icon(Icons.phone_rounded, color: Colors.white),
        label: const Text(
          'Contact Admin',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
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
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
