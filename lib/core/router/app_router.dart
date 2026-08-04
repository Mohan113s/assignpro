import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/user/screens/user_dashboard_screen.dart';
import '../../core/storage/token_storage.dart';

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

  /// Determine initial route from saved JWT session.
  /// AppProvider.initialize() will re-validate the token against the backend;
  /// if expired it clears the token and the user will see login.
  static String getInitialRoute() {
    if (!TokenStorage.isLoggedIn()) return login;
    final role = TokenStorage.getSavedUserRole();
    if (role == 'admin') return adminDashboard;
    if (role == 'user') return userDashboard;
    return login;
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
