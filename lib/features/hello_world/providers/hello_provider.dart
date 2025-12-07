import 'package:altu_life/features/hello_world/data/repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for hello repository.
final helloRepositoryProvider = Provider<HelloRepository>(
  (ref) => HelloRepository(),
);

/// Provider for hello message state.
final helloMessageProvider = FutureProvider<String>((ref) async {
  final repository = ref.watch(helloRepositoryProvider);
  return repository.getHelloMessage();
});
