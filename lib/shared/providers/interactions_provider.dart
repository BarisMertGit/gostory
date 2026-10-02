import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/interactions_service.dart';
import 'auth_provider.dart';

final interactionsServiceProvider = Provider((ref) {
  final service = InteractionsService();
  ref.onDispose(service.dispose);
  return service;
});
final interactionsProvider = StreamProvider.autoDispose
    .family<MemoryInteractions, String>((ref, id) async* {
  final user = await ref.watch(authStateProvider.future);
  yield* ref.watch(interactionsServiceProvider).watch(id, user.uid);
});
