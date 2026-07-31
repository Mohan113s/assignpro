import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/app_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/common_widgets.dart';
import 'user_home_tab.dart';
import 'user_leads_screen.dart';
import 'user_notes_screen.dart';
import 'user_profile_screen.dart';
import 'package:url_launcher/url_launcher.dart';

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
    _NavItem(
      icon: Icons.note_alt_rounded,
      label: 'Notepad',
      screen: const UserNotesScreen(),
    ),
    _NavItem(
      icon: Icons.person_rounded,
      label: 'Profile',
      screen: const UserProfileScreen(),
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
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        AppSnackbar.error(context, 'Could not launch phone dialer.');
      }
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
            icon: const Icon(Icons.logout_rounded),
            onPressed: _logout,
            tooltip: 'Sign Out',
          ),
          const SizedBox(width: 4),
          Padding(
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _contactAdmin,
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(Icons.phone_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Contact Admin',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        elevation: 4,
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
