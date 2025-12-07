import 'package:altu_life/features/hello_world/providers/hello_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hello World screen.
///
/// This is the main screen of the application that displays
/// the app logo and a centered "Hello World 👋" message.
class HelloScreen extends ConsumerWidget {
  /// Creates a [HelloScreen] widget.
  const HelloScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helloMessageAsync = ref.watch(helloMessageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Altu Life')),
      body: Center(
        child: helloMessageAsync.when(
          data: (message) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/app-logo.jpeg',
                height: 120,
                width: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Text(
                message,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, stackTrace) => Text(
            'Error: $error',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}
