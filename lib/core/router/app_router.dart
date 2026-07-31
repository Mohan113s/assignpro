import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/user/screens/user_dashboard_screen.dart';
import '../../core/services/local_storage_service.dart';
import '../../features/auth/models/user_model.dart';

class AppRouter {
  static const String login = '/login';
  static const String register = '/register';
  static const String adminDashboard = '/admin';
  static const String userDashboard = '/user';
  static const String splash = '/';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _fade(const LoginScreen());
      case register:
        return _fade(const RegisterScreen());
      case adminDashboard:
        return _fade(const AdminDashboardScreen());
      case userDashboard:
        return _fade(const UserDashboardScreen());
      default:
        return _fade(const LoginScreen());
    }
  }

  static String getInitialRoute() {
    if (!LocalStorageService.isLoggedIn()) return login;
    final userId = LocalStorageService.getCurrentUserId();
    if (userId == null) return login;
    final user = LocalStorageService.getUserById(userId);
    if (user == null) return login;
    if (!user.isActive) return login;
    return user.role == UserRole.admin ? adminDashboard : userDashboard;
  }

  static PageRoute _fade(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
