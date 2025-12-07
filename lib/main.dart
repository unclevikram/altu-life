import 'package:altu_life/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Application entry point.
///
/// This is the main function that initializes the Flutter application
/// with Riverpod's ProviderScope and runs the App widget.
void main() {
  runApp(const ProviderScope(child: App()));
}
