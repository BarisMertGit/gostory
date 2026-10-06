import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme/colors.dart';
import '../providers/location_provider.dart';
import '../providers/memories_provider.dart';
import 'location_access.dart';
import 'map_attribution.dart';
import 'map_tiles.dart';

final draftLocationProvider = StateProvider<LatLng?>((ref) => null);

final draftLocationNameProvider =
    FutureProvider.autoDispose.family<String, LatLng>((ref, point) async {
  try {
    return await ref
            .read(memoryStoreProvider)
            .resolveCity
            ?.call(point.latitude, point.longitude) ??
        '';
  } catch (_) {
    return '';
  }
});

class LocationChip extends ConsumerWidget {
  const LocationChip({super.key, this.enabled = true});
  final bool enabled;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final point = ref.watch(draftLocationProvider);
    final name = point == null
        ? ''
        : ref.watch(draftLocationNameProvider(point)).valueOrNull ?? '';
    final locating = ref.watch(locationAccessProvider).busy && point == null;
    return Semantics(
      liveRegion: true,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          backgroundColor: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(44, 44),
        ),
        icon: locating
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.location_on_outlined, size: 18),
        label: Text(
          locating
              ? 'Konum alınıyor…'
              : point == null
                  ? 'Konum ekle'
                  : '${name.isNotEmpty ? name : '${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)}'} · Konumu değiştir',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
        onPressed: !enabled
            ? null
            : () async {
                final result = await Navigator.push<LatLng>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LocationPicker(initial: point),
                  ),
                );
                if (context.mounted && result != null) {
                  ref.read(draftLocationProvider.notifier).state = result;
                }
              },
      ),
    );
  }
}

class LocationPicker extends ConsumerStatefulWidget {
  const LocationPicker({super.key, this.initial});
  final LatLng? initial;
  @override
  ConsumerState<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends ConsumerState<LocationPicker> {
  final _controller = MapController();
  LatLng? _point;
  bool _awaitingLocation = false;
  @override
  void initState() {
    super.initState();
    _point = widget.initial;
    _awaitingLocation = _point == null && ref.read(locationAccessProvider).busy;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    _awaitingLocation = true;
    await requestDeviceLocation(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(locationAccessProvider);
    ref.listen(locationAccessProvider, (previous, next) {
      // Also follow requests started by retry/settings feedback in this picker.
      if (next.busy && !(previous?.busy ?? false)) {
        _awaitingLocation = true;
      }
      if (!next.busy && next.position == null) {
        _awaitingLocation = false;
      }
      if (!_awaitingLocation || next.position == null) return;
      final position = next.position!;
      setState(() => _point = LatLng(position.latitude, position.longitude));
      _controller.move(_point!, 14);
      _awaitingLocation = false;
    });
    return Scaffold(
      backgroundColor: AppColors.mapSurface,
      appBar: AppBar(title: const Text('Konum seç')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Anının yerini haritaya dokunarak seç.'),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: _point ?? const LatLng(20, 0),
                initialZoom: _point == null ? 2 : 15,
                onTap: (_, point) => setState(() {
                  _awaitingLocation = false;
                  _point = point;
                }),
              ),
              children: [
                TileLayer(
                  tileBuilder: mapTileBuilder,
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.gostory.app',
                ),
                if (_point != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _point!,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppColors.peach,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const MapAttribution(),
                  const LocationFeedback(),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: access.busy ? null : _locate,
                          icon: const Icon(Icons.my_location),
                          label: Text(
                            access.busy ? 'Konum alınıyor…' : 'Konumumu bul',
                          ),
                        ),
                      ),
                      Expanded(
                        child: FilledButton(
                          onPressed: _point == null
                              ? null
                              : () => Navigator.pop(context, _point),
                          child: const Text('Bu konumu seç'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
