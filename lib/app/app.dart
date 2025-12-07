import 'package:altu_life/app/router/app_router.dart';
import 'package:altu_life/app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root application widget.
///
/// This widget wraps the entire application with necessary providers
/// and configures the theme and routing.
class App extends ConsumerWidget {
  /// Creates an [App] widget.
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Altu Life',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    routerConfig: appRouter,
  );
}
