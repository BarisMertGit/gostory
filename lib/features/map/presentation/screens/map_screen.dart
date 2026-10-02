import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/navigation.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/design.dart';
import '../../../../shared/models/memory.dart';
import '../../../../shared/providers/location_provider.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../shared/widgets/location_access.dart';
import '../../../../shared/widgets/location_permission_band.dart';
import '../../../memory/presentation/memory_detail_screen.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../domain/map_state.dart';
import '../providers/map_provider.dart';
import '../widgets/discovery_controls.dart';
import '../widgets/discovery_map.dart';
import '../widgets/discovery_memory_card.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, this.embedded = false});
  final bool embedded;
  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapKey = GlobalKey<DiscoveryMapState>();
  final _sheet = DraggableScrollableController();
  int _filter = 1;
  String? _selectedId;
  LatLngBounds? _bounds;
  double _extent = 0;
  double _minimum = .2;
  double _mapHeight = 400;
  bool _loadingMore = false;

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  void _share() {
    if (widget.embedded) {
      ref.read(selectedTabProvider.notifier).state = 1;
    } else {
      Navigator.pushNamed(context, AppRoutes.camera);
    }
  }

  void _expand(bool expand) {
    if (!_sheet.isAttached) return;
    final target = expand ? math.max(_minimum, .58) : _minimum;
    if (MediaQuery.disableAnimationsOf(context)) {
      _sheet.jumpTo(target);
    } else {
      _sheet.animateTo(target,
          duration: AppMotion.duration(context), curve: Curves.easeOutCubic,);
    }
  }

  void _select(Memory memory) {
    setState(() => _selectedId = memory.id);
    _expand(true);
    _mapKey.currentState?.focusMemory(memory,
        bottomInset: _mapHeight * math.max(_minimum, .58),);
  }

  Future<void> _more() async {
    setState(() => _loadingMore = true);
    try {
      await ref.read(mapProvider.notifier).loadMore();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Anılar yüklenemedi. Tekrar dene.')),);
      }
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  bool _sameBounds(LatLngBounds? a, LatLngBounds b) =>
      a != null &&
      (a.southWest.latitude - b.southWest.latitude).abs() < .000001 &&
      (a.southWest.longitude - b.southWest.longitude).abs() < .000001 &&
      (a.northEast.latitude - b.northEast.latitude).abs() < .000001 &&
      (a.northEast.longitude - b.northEast.longitude).abs() < .000001;

  double _distance(Memory memory, MapReady state) => const Distance()(
        LatLng(state.userLatitude, state.userLongitude),
        LatLng(memory.latitude, memory.longitude),
      );

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapProvider);
    ref.listen(locationAccessProvider, (_, next) {
      if (next.position != null &&
          (!widget.embedded || ref.read(selectedTabProvider) == 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _mapKey.currentState?.focusLocation(
                next.position!.latitude, next.position!.longitude,);
          }
        });
      }
    });
    return Scaffold(
        body: SafeArea(
            bottom: !widget.embedded,
            child: switch (state) {
              MapLoading() => const Center(child: CircularProgressIndicator()),
              MapError(:final message) => EmptyState(
                  icon: Icons.map_outlined,
                  title: 'Anılar yüklenemedi',
                  message: message,
                  action: PrimaryAction(
                      label: 'Tekrar dene',
                      onPressed: () =>
                          ref.read(mapProvider.notifier).refresh(),),),
              MapReady() => _discovery(state),
            },),);
  }

  Widget _discovery(MapReady state) {
    final items = state.memories.toList()
      ..sort((a, b) => switch (_filter) {
            1 => b.createdAt.compareTo(a.createdAt),
            2 => b.viewCount.compareTo(a.viewCount),
            _ => state.hasUserLocation
                ? _distance(a, state).compareTo(_distance(b, state))
                : b.createdAt.compareTo(a.createdAt),
          },);
    final nearby = items
        .where((m) =>
            _bounds == null ||
            _bounds!.contains(LatLng(m.latitude, m.longitude)),)
        .toList();
    final selectedIndex = nearby.indexWhere((m) => m.id == _selectedId);
    if (selectedIndex > 0) nearby.insert(0, nearby.removeAt(selectedIndex));
    return Column(children: [
      PageHeading(
          title: 'Keşfet',
          subtitle: 'Yakınındaki anıları keşfet',
          trailing: widget.embedded ? null : const BackButton(),),
      Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: FilterControl(
            labels: const ['Yakınımda', 'Yeni', 'Popüler'],
            selected: _filter,
            onSelected: (index) {
              setState(() {
                _filter = index;
                _selectedId = null;
              });
              if (index == 0 && !state.hasUserLocation) {
                requestDeviceLocation(context, ref);
              }
            },
          ),),
      const LocationPermissionBand(),
      Expanded(child: LayoutBuilder(builder: (context, constraints) {
        final headerHeight =
            44 + MediaQuery.textScalerOf(context).scale(16) * 1.4;
        _mapHeight = constraints.maxHeight;
        _minimum = (headerHeight / _mapHeight).clamp(.1, .6);
        final visibleExtent = _extent.clamp(_minimum, .88);
        final expanded = visibleExtent > _minimum + .025;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Stack(children: [
            Positioned.fill(
                child: DiscoveryMap(
              key: _mapKey,
              memories: items,
              selectedId: _selectedId,
              hasUserLocation: state.hasUserLocation,
              latitude: state.userLatitude,
              longitude: state.userLongitude,
              onSelect: _select,
              onCluster: (memories) => _select(memories.first),
              onBoundsChanged: (bounds) {
                if (mounted && !_sameBounds(_bounds, bounds)) {
                  setState(() => _bounds = bounds);
                }
              },
            ),),
            if (_mapHeight * (1 - visibleExtent) > 64)
              Positioned(
                top: 12,
                right: 12,
                child: DiscoveryControls(
                  compact: _mapHeight * (1 - visibleExtent) < 164,
                  onZoomIn: () => _mapKey.currentState?.zoomBy(2),
                  onZoomOut: () => _mapKey.currentState?.zoomBy(.5),
                  onLocate: () => requestDeviceLocation(context, ref),
                ),
              ),
            if (_mapHeight * (1 - visibleExtent) > 96)
              Positioned(
                left: 16,
                bottom: _mapHeight * visibleExtent + 12,
                child: LeaveMemoryButton(onPressed: _share),
              ),
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                if ((_extent - notification.extent).abs() > .001) {
                  setState(() => _extent = notification.extent);
                }
                return false;
              },
              child: DraggableScrollableSheet(
                controller: _sheet,
                initialChildSize: _minimum,
                minChildSize: _minimum,
                maxChildSize: .88,
                snap: !MediaQuery.disableAnimationsOf(context),
                snapSizes: [math.max(_minimum, .58)],
                snapAnimationDuration: MediaQuery.disableAnimationsOf(context)
                    ? null
                    : AppMotion.duration(context),
                builder: (context, scrollController) => Material(
                  color: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(AppRadii.sheet),),
                      side: BorderSide(color: AppColors.divider),),
                  clipBehavior: Clip.antiAlias,
                  child: CustomScrollView(
                    key: const ValueKey('map-memory-panel'),
                    controller: scrollController,
                    slivers: [
                      SliverPersistentHeader(
                          pinned: true,
                          delegate: _PanelHeader(
                            height: headerHeight,
                            count: nearby.length,
                            expanded: expanded,
                            onTap: () => _expand(!expanded),
                          ),),
                      if (nearby.isEmpty)
                        SliverToBoxAdapter(
                            child: EmptyState(
                          icon: Icons.add_location_alt_outlined,
                          title: 'Buraya ilk anıyı sen bırak',
                          message:
                              'Haritayı gez veya bu yere kendi hikâyeni ekle.',
                          action: LeaveMemoryButton(onPressed: _share),
                        ),)
                      else
                        SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            sliver: SliverList.builder(
                              itemCount: nearby.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: DiscoveryMemoryCard(
                                  key: ValueKey(nearby[index].id == _selectedId
                                      ? 'selected-memory-card'
                                      : nearby[index].id,),
                                  memory: nearby[index],
                                  distance: state.hasUserLocation
                                      ? _distance(nearby[index], state)
                                      : null,
                                  selected: nearby[index].id == _selectedId,
                                  onTap: () =>
                                      openMemoryDetail(context, nearby[index]),
                                  onAuthorTap: () =>
                                      openPublicProfile(context, nearby[index]),
                                ),
                              ),
                            ),),
                      if (ref.read(mapProvider.notifier).hasMore)
                        SliverToBoxAdapter(
                            child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: PrimaryAction(
                              label: 'Daha fazla anı',
                              busy: _loadingMore,
                              onPressed: _more,),
                        ),),
                    ],
                  ),
                ),
              ),
            ),
          ],),
        );
      },),),
      // Attribution has its own layout space, outside the sheet and navigation.
      Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () =>
                launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')),
            child: const Text('© OpenStreetMap contributors',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),),
          ),),
    ],);
  }
}

class _PanelHeader extends SliverPersistentHeaderDelegate {
  _PanelHeader(
      {required this.height,
      required this.count,
      required this.expanded,
      required this.onTap,});
  final double height;
  final int count;
  final bool expanded;
  final VoidCallback onTap;
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;
  @override
  bool shouldRebuild(covariant _PanelHeader old) =>
      height != old.height || count != old.count || expanded != old.expanded;
  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent,) =>
      Material(
        color: AppColors.surface,
        child: Semantics(
            button: true,
            expanded: expanded,
            label: 'Anılar paneli',
            child: InkWell(
              onTap: onTap,
              child: Column(children: [
                Container(
                    width: 32,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 10),
                    decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(4),),),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Expanded(
                          child: Text('Bu bölgede $count anı',
                              style: Theme.of(context).textTheme.titleSmall,),),
                      Icon(
                          expanded
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          color: AppColors.peach,
                          size: 22,),
                    ],),),
              ],),
            ),),
      );
}
