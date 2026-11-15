import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'core/di/configure_providers.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final di = await ConfigureProviders.createDependencyTree();
  runApp(BookyApp(di: di));
}

class BookyApp extends StatelessWidget {
  final ConfigureProviders di;

  const BookyApp({super.key, required this.di});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: di.providers,
      child: AnimatedBuilder(
        animation: themeController,
        builder: (context, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeController.themeMode,
            initialRoute: AppRoutes.initial,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}
