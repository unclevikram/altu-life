import 'package:altu_life/app/router/app_router.dart';
import 'package:altu_life/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root application widget.
///
/// Configures the MaterialApp with:
/// - Custom theme matching the React app
/// - GoRouter for navigation
/// - Riverpod for state management
class App extends ConsumerWidget {
  /// Creates an [App] widget.
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Altu Health',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.light, // Match React app (light only)
    routerConfig: appRouter,
  );
}
