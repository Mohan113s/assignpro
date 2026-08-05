import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/providers/app_provider.dart';
import 'core/router/app_router.dart';
import 'core/storage/token_storage.dart';
import 'core/services/token_storage_service.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode on Android/iOS
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize BOTH token storage implementations to ensure consistency.
  // TokenStorage (network/) is the canonical one used by AppProvider.
  // TokenStorageService (services/) is kept for backward compat.
  await TokenStorage.init();
  await TokenStorageService.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..initialize(),
      child: const AssignProApp(),
    ),
  );
}

class AssignProApp extends StatelessWidget {
  const AssignProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AssignPro CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRouter.getInitialRoute(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
