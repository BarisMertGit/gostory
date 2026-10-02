import 'package:flutter/widgets.dart';
import '../../../../shared/models/memory.dart';

class MemoryCluster {
  MemoryCluster(this.anchor, Memory memory) : memories = [memory];
  final Offset anchor;
  final List<Memory> memories;
}

/// Screen-space buckets, with neighbour checks so cell boundaries don't split pins.
List<MemoryCluster> clusterMemories(
  List<Memory> memories,
  Offset Function(Memory) project, {
  double radius = 48,
}) {
  final buckets = <(int, int), List<MemoryCluster>>{};
  final clusters = <MemoryCluster>[];
  for (final memory in memories) {
    final point = project(memory);
    final x = (point.dx / radius).floor();
    final y = (point.dy / radius).floor();
    MemoryCluster? match;
    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        for (final candidate
            in buckets[(x + dx, y + dy)] ?? <MemoryCluster>[]) {
          if ((candidate.anchor - point).distance < radius) {
            match = candidate;
            break;
          }
        }
        if (match != null) break;
      }
      if (match != null) break;
    }
    if (match != null) {
      match.memories.add(memory);
    } else {
      final cluster = MemoryCluster(point, memory);
      clusters.add(cluster);
      (buckets[(x, y)] ??= []).add(cluster);
    }
  }
  return clusters;
}
