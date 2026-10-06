import 'package:camera/camera.dart' as cam;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/navigation.dart';
import '../../../../app/router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/design.dart';
import '../../../../app/theme/spacing.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/permission_explanation.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../shared/widgets/location_chip.dart';
import '../../domain/camera_state.dart';
import '../providers/camera_provider.dart';
import '../widgets/shutter_button.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key, this.embedded = false, this.active = true});
  final bool embedded;
  final bool active;
  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver, RouteAware {
  bool _starting = false;
  bool _initializing = false;
  bool _resumePending = false;
  bool _previewOpen = false;
  bool _usedCamera = false;
  bool _routeVisible = true;
  bool _foreground = true;
  int _epoch = 0;
  late CameraNotifier _notifier;
  PageRoute<dynamic>? _route;
  List<cam.CameraDescription> _cameras = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _notifier = ref.read(cameraProvider.notifier);
  }

  @override
  void didUpdateWidget(covariant CameraScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active && !widget.active) {
      _stop();
    } else if (!oldWidget.active && widget.active && _usedCamera) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _start(interactive: false);
      });
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    ++_epoch;
    _notifier.release();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _route) {
      appRouteObserver.unsubscribe(this);
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  void _stop() {
    ++_epoch;
    _notifier.suspend();
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _stop();
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    if (_usedCamera) _start(interactive: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      if (_usedCamera && !_previewOpen && _routeVisible) {
        if (_starting) {
          _resumePending = true;
        } else {
          _start(interactive: false);
        }
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _stop();
    } else if (state == AppLifecycleState.inactive && !_starting) {
      _stop();
    }
  }

  Future<void> _start({bool interactive = true}) async {
    if (_starting ||
        !mounted ||
        !widget.active ||
        !_routeVisible ||
        !_foreground) {
      return;
    }
    setState(() => _starting = true);
    final epoch = _epoch;
    bool active() =>
        mounted &&
        widget.active &&
        _routeVisible &&
        _foreground &&
        epoch == _epoch;
    try {
      final permissions = ref.read(permissionServiceProvider);
      final status = await permissions.status('camera');
      if (!mounted || !active()) return;
      if (status == AccessStatus.blocked || status == AccessStatus.restricted) {
        _usedCamera = true;
        _notifier.permissionDenied(permanently: true);
        if (interactive &&
            await explainPermission(
              context,
              settings: true,
              message:
                  'Kamera izni sistem tarafından engellenmiş. İzni cihaz ayarlarından açabilirsin.',
            ) &&
            mounted &&
            active()) {
          await permissions.openSettings();
        }
        return;
      }
      if (status != AccessStatus.granted) {
        if (!interactive) {
          _notifier.permissionDenied();
          return;
        }
        if (!await explainPermission(context, message: cameraExplanation) ||
            !active()) {
          return;
        }
      }
      if (!mounted || !active()) return;
      setState(() => _initializing = true);
      _usedCamera = true;
      // Enumerate cameras only after the user's camera action.
      ref.invalidate(availableCamerasProvider);
      final cameras = await ref.read(availableCamerasProvider.future);
      if (!active()) return;
      _cameras = cameras;
      if (cameras.isNotEmpty && status != AccessStatus.granted) {
        await permissions.markRequested('camera');
      }
      if (!active()) return;
      await _notifier.initialize(cameras);
      if (!active()) return;
      if (ref.read(cameraProvider) is CameraPermissionDenied) {
        final after = await permissions.status('camera');
        if (active()) {
          _notifier.permissionDenied(
            permanently: after == AccessStatus.blocked ||
                after == AccessStatus.restricted,
          );
        }
      }
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'camera_screen',
        error: error.runtimeType,
        stackTrace: stack,
      );
      if (active()) {
        _notifier.fail(
          'Kamera veya izin durumu okunamadı. Tekrar dene.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _starting = false;
          _initializing = false;
        });
        if (_resumePending &&
            _usedCamera &&
            _foreground &&
            _routeVisible &&
            !_previewOpen) {
          _resumePending = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _start(interactive: false);
          });
        }
      }
    }
  }

  Future<void> _preview(String path) async {
    if (_previewOpen) return;
    _previewOpen = true;
    await ref.read(cameraProvider.notifier).suspend();
    if (!mounted) return;
    await Navigator.pushNamed(context, AppRoutes.preview, arguments: path);
    _previewOpen = false;
    if (mounted && _usedCamera) await _start(interactive: false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cameraProvider);
    ref.listen(cameraProvider, (_, next) {
      if (widget.active && next is CameraCaptured) _preview(next.photoPath);
    });
    final controller = ref.read(cameraProvider.notifier).controller;
    final ready = state is CameraReady && controller != null;
    final loading = state is CameraLoading || _initializing;
    final canSwitch = _cameras
            .any((c) => c.lensDirection == cam.CameraLensDirection.front) &&
        _cameras.any((c) => c.lensDirection == cam.CameraLensDirection.back);
    return Scaffold(
      body: SafeArea(
        bottom: !widget.embedded,
        child: Column(
          children: [
            PageHeading(
              title: 'Bir anı paylaş',
              trailing: widget.embedded ? null : const BackButton(),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child:
                  Align(alignment: Alignment.centerLeft, child: LocationChip()),
            ),
            Expanded(
              child: ready
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        0,
                        AppSpacing.screenPadding,
                        AppSpacing.md,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(AppRadii.card),
                              child: ColoredBox(
                                color: AppColors.surface,
                                child: Center(
                                  child: cam.CameraPreview(controller),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ValueListenableBuilder<cam.CameraValue>(
                            valueListenable: controller,
                            builder: (context, value, _) => Row(
                              children: [
                                const Expanded(child: SizedBox()),
                                ShutterButton(
                                  enabled: !value.isTakingPicture,
                                  onPressed: () => ref
                                      .read(cameraProvider.notifier)
                                      .capturePhoto(),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: canSwitch
                                        ? IconButton.filledTonal(
                                            tooltip: 'Kamerayı çevir',
                                            onPressed: value.isTakingPicture
                                                ? null
                                                : () => ref
                                                    .read(
                                                      cameraProvider.notifier,
                                                    )
                                                    .switchCamera(_cameras),
                                            icon: const Icon(
                                              Icons.cameraswitch_outlined,
                                            ),
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : AdaptiveStateBody(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        AppSpacing.sm,
                        AppSpacing.screenPadding,
                        AppSpacing.lg,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: loading
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.xl,
                                ),
                                child: Semantics(
                                  liveRegion: true,
                                  child: const Column(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: AppSpacing.lg),
                                      Text('Kamera açılıyor…'),
                                    ],
                                  ),
                                ),
                              )
                            : _starter(state),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _starter(CameraState state) {
    final denied = state is CameraPermissionDenied;
    final settings = denied && state.permanentlyDenied;
    final idle = state is CameraIdle || state is CameraCaptured;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Icon(
            denied ? Icons.no_photography_outlined : Icons.camera_alt_outlined,
            size: 36,
            color: AppColors.peach,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          idle
              ? 'Bir fotoğrafla başla'
              : denied
                  ? 'Kamera izni gerekli'
                  : 'Kamera kullanılamıyor',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          state is CameraError
              ? state.message
              : denied
                  ? settings
                      ? 'Kamera erişimini cihaz ayarlarından açabilirsin.'
                      : 'Bu anı yakalamak için kameraya erişim ver.'
                  : 'Hatırlamak istediğin anı yakala. Kısa bir not ekle, konumuyla sakla.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryAction(
          label: settings
              ? 'Ayarları aç'
              : state is CameraError
                  ? 'Tekrar dene'
                  : denied
                      ? 'İzin ver'
                      : 'Kamerayı aç',
          onPressed: _starting ? null : () => _start(),
        ),
      ],
    );
  }
}
