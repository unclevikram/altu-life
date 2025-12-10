import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Creates a [ProviderContainer] for testing Riverpod providers.
///
/// Usage:
/// ```dart
/// test('provider test', () {
///   final container = createProviderContainer();
///   final value = container.read(myProvider);
///   expect(value, equals(expectedValue));
///   container.dispose();
/// });
/// ```
ProviderContainer createProviderContainer({
  List<Override> overrides = const [],
  ProviderContainer? parent,
}) {
  final container = ProviderContainer(
    overrides: overrides,
    parent: parent,
  );

  // Clean up the container after the test
  addTearDown(container.dispose);

  return container;
}

/// Listens to a provider and returns a listener for testing.
///
/// Usage:
/// ```dart
/// test('provider listener test', () {
///   final container = createProviderContainer();
///   final listener = createProviderListener<String>();
///
///   container.listen(
///     myProvider,
///     listener,
///     fireImmediately: true,
///   );
///
///   verify(() => listener(null, 'initial value')).called(1);
/// });
/// ```
T Function(T? previous, T next) createProviderListener<T>() {
  final states = <T>[];

  return (previous, next) {
    states.add(next);
  };
}
