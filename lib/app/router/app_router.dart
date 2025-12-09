import 'package:altu_life/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Application router configuration using GoRouter.
///
/// Defines the navigation routes for Altu Health app.
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'home',
      builder: (BuildContext context, GoRouterState state) =>
          const HomeScreen(),
    ),
  ],
  // Error builder for handling unknown routes
  errorBuilder: (BuildContext context, GoRouterState state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
);
