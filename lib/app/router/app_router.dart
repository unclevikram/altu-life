import 'package:altu_life/features/hello_world/presentation/screens/hello_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Application router configuration using GoRouter.
///
/// This file defines all routes in the application.
/// Routes are defined here to enable navigation throughout the app.
final GoRouter appRouter = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      name: 'hello',
      builder: (BuildContext context, GoRouterState state) =>
          const HelloScreen(),
    ),
  ],
  // Error builder for handling unknown routes
  errorBuilder: (BuildContext context, GoRouterState state) =>
      Scaffold(body: Center(child: Text('Page not found: ${state.uri}'))),
);
