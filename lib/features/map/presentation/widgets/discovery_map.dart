import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/design.dart';
import '../../../../shared/models/memory.dart';
import 'memory_clusters.dart';

/// Geographic world map shared by preview and device builds.
class DiscoveryMap extends StatefulWidget {
  const DiscoveryMap({
    super.key,
    required this.memories,
    required this.selectedId,
    required this.latitude,
    required this.longitude,
    required this.onSelect,
    this.onInteraction,
    this.tileProvider,
    this.hasUserLocation = true,
    this.onBoundsChanged,
    this.onCluster,
  });
  final ValueChanged<List<Memory>>? onCluster;
  final List<Memory> memories;
  final String? selectedId;
  final double latitude;
  final double longitude;
  final ValueChanged<Memory> onSelect;
  final VoidCallback? onInteraction;
  final TileProvider? tileProvider;
  final bool hasUserLocation;
  final ValueChanged<LatLngBounds>? onBoundsChanged;

  @override
  State<DiscoveryMap> createState() => DiscoveryMapState();
}

class DiscoveryMapState extends State<DiscoveryMap> {
  final controller = MapController();
  bool _ready = false;

  void zoomBy(double factor) {
    if (!_ready) return;
    controller.move(
      controller.camera.center,
      (controller.camera.zoom + math.log(factor) / math.ln2).clamp(2.0, 19.0),
    );
  }

  void focusLocation(double latitude, double longitude) {
    if (!_ready) return;
    controller.move(LatLng(latitude, longitude), 13);
  }

  void resetView() {
    if (!_ready) return;
    controller.rotate(0);
    controller.move(LatLng(widget.latitude, widget.longitude), 13);
  }

  void showWorld() {
    if (!_ready) return;
    widget.onInteraction?.call();
    controller.rotate(0);
    controller.move(const LatLng(20, 0), 2);
  }

  void focusMemory(Memory memory, {double bottomInset = 0}) {
    if (!_ready) return;
    controller.move(
      LatLng(memory.latitude, memory.longitude),
      math.max(controller.camera.zoom, 15),
      offset: Offset(0, -bottomInset / 2),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: LatLng(widget.latitude, widget.longitude),
          initialZoom:
              widget.hasUserLocation || widget.memories.isNotEmpty ? 13 : 2,
          minZoom: 2,
          maxZoom: 19,
          backgroundColor: const Color(0xFF242E2B),
          onMapReady: () {
            _ready = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                widget.onBoundsChanged?.call(controller.camera.visibleBounds);
              }
            });
          },
          onPositionChanged: (camera, hasGesture) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) widget.onBoundsChanged?.call(camera.visibleBounds);
            });
            if (hasGesture) widget.onInteraction?.call();
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.gostory.app',
            tileProvider: widget.tileProvider,
          ),
          Builder(builder: (context) {
            final camera = MapCamera.of(context);
            final clusters = clusterMemories(
                widget.memories,
                (memory) => camera.latLngToScreenOffset(
                    LatLng(memory.latitude, memory.longitude),),);
            return MarkerLayer(markers: [
              if (widget.hasUserLocation)
                Marker(
                  point: LatLng(widget.latitude, widget.longitude),
                  width: 28,
                  height: 28,
                  child: Semantics(
                      label: 'Cihaz konumun',
                      child: Container(
                        decoration: BoxDecoration(
                            color: AppColors.peach.withValues(alpha: .25),
                            shape: BoxShape.circle,),
                        padding: const EdgeInsets.all(7),
                        child: Container(
                            decoration: BoxDecoration(
                                color: AppColors.onPeach,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: AppColors.peach, width: 2,),),),
                      ),),
                ),
              for (final cluster in clusters)
                Marker(
                  point: LatLng(cluster.memories.first.latitude,
                      cluster.memories.first.longitude,),
                  width: 48,
                  height: 48,
                  child: _pin(context, cluster),
                ),
            ],);
          },),
        ],
      );

  Widget _pin(BuildContext context, MemoryCluster cluster) {
    final memory = cluster.memories.first;
    final grouped = cluster.memories.length > 1;
    final selected = cluster.memories.any((m) => m.id == widget.selectedId);
    final label = grouped
        ? '${cluster.memories.length} anı, kümeyi aç'
        : 'Anı: ${memory.textNote}';
    return Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Tooltip(
          message: label,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              if (!grouped) {
                widget.onSelect(memory);
              } else if (controller.camera.zoom >= 17 ||
                  cluster.memories.every((m) =>
                      m.latitude == memory.latitude &&
                      m.longitude == memory.longitude,)) {
                widget.onCluster?.call(cluster.memories);
              } else {
                controller.move(LatLng(memory.latitude, memory.longitude),
                    (controller.camera.zoom + 2).clamp(2.0, 19.0),);
              }
            },
            child: Center(
                child: AnimatedContainer(
              duration: AppMotion.duration(context),
              width: selected ? 42 : 38,
              height: selected ? 42 : 38,
              decoration: BoxDecoration(
                color:
                    selected || grouped ? AppColors.peach : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.peach, width: selected ? 2 : 1),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),),
                ],
              ),
              child: Center(
                  child: grouped
                      ? Text('${cluster.memories.length}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onPeach,),)
                      : Icon(Icons.photo_camera_outlined,
                          size: 19,
                          color:
                              selected ? AppColors.onPeach : AppColors.peach,),),
            ),),
          ),
        ),);
  }
}
