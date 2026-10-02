import 'package:gostory/shared/models/memory.dart';
import 'package:gostory/shared/providers/memories_provider.dart';

class EmptyMemoryStore extends MemoryStore {
  @override
  Future<List<Memory>> read() async => [];
}
