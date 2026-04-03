import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_flutter/core/router/app_router.dart';
import 'package:frontend_flutter/core/theme/app_theme.dart';
import 'package:frontend_flutter/shared/providers/accessibility_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final highContrast = ref.watch(highContrastProvider);

    return MaterialApp.router(
      title: 'Good App',
      debugShowCheckedModeBanner: false,
      theme: highContrast ? AppTheme.highContrastTheme : AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
