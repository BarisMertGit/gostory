import 'dart:async';

import 'package:camera/camera.dart' as cam;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/preview_config.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/camera_state.dart';

final availableCamerasProvider =
    FutureProvider<List<cam.CameraDescription>>((ref) async {
  if (PreviewConfig.enabled) return [];
  return cam.availableCameras();
});

class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier() : super(const CameraIdle());
  cam.CameraController? _controller;
  cam.CameraController? get controller => _controller;
  int _generation = 0;
  Future<void> _closing = Future.value();

  void permissionDenied({bool permanently = false}) {
    if (mounted) state = CameraPermissionDenied(permanentlyDenied: permanently);
  }

  void fail(String message) {
    if (mounted) state = CameraError(message: message);
  }

  Future<void> initialize(List<cam.CameraDescription> cameras) async {
    if (!mounted) return;
    if (cameras.isEmpty) {
      state = const CameraError(
        message: 'Bu cihazda kullanılabilir kamera bulunamadı.',
      );
      return;
    }
    await _initController(
      cameras.firstWhere(
        (c) => c.lensDirection == cam.CameraLensDirection.back,
        orElse: () => cameras.first,
      ),
    );
  }

  Future<void> _initController(cam.CameraDescription camera) async {
    final generation = ++_generation;
    if (!mounted) return;
    state = const CameraLoading();
    await _disposeController();
    if (!mounted || generation != _generation) return;
    final active = cam.CameraController(
      camera,
      cam.ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: cam.ImageFormatGroup.jpeg,
    );
    _controller = active;
    try {
      await active.initialize();
      if (!mounted || generation != _generation) return;
      await active.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (!mounted || generation != _generation) return;
      state = const CameraReady();
    } on cam.CameraException catch (error) {
      if (!mounted || generation != _generation) return;
      await _disposeController();
      if (!mounted || generation != _generation) return;
      if (error.code.startsWith('CameraAccess')) {
        permissionDenied(permanently: error.code != 'CameraAccessDenied');
      } else {
        fail(
          'Kamera başlatılamadı. Başka bir uygulama kamerayı kullanıyor olabilir. Kapatıp tekrar dene.',
        );
      }
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'camera_provider',
        error: error.runtimeType,
        stackTrace: stack,
      );
      if (!mounted || generation != _generation) return;
      await _disposeController();
      if (mounted && generation == _generation) {
        fail('Kameraya erişilemiyor. Tekrar dene.');
      }
    }
  }

  Future<void> capturePhoto() async {
    final active = _controller;
    final generation = _generation;
    if (state is! CameraReady ||
        active == null ||
        !active.value.isInitialized ||
        active.value.isTakingPicture) {
      return;
    }
    try {
      final photo = await active.takePicture();
      final dir = await getTemporaryDirectory();
      final path = p.join(
        dir.path,
        'gostory_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await photo.saveTo(path);
      if (mounted && generation == _generation) {
        state = CameraCaptured(photoPath: path);
      }
    } catch (error, stack) {
      AppLogger.error(
        'İşlem başarısız.',
        tag: 'camera_provider',
        error: error.runtimeType,
        stackTrace: stack,
      );
      if (mounted && generation == _generation) {
        await suspend();
        fail(
          'Fotoğraf çekilemedi. Kamerayı yeniden açıp dene.',
        );
      }
    }
  }

  void resetToReady() {
    if (mounted && _controller?.value.isInitialized == true) {
      state = const CameraReady();
    }
  }

  Future<void> switchCamera(List<cam.CameraDescription> cameras) async {
    if (state is! CameraReady) return;
    final direction = _controller?.description.lensDirection;
    final alternatives = cameras.where(
      (c) =>
          c.lensDirection != direction &&
          (c.lensDirection == cam.CameraLensDirection.front ||
              c.lensDirection == cam.CameraLensDirection.back),
    );
    if (alternatives.isNotEmpty) await _initController(alternatives.first);
  }

  Future<void> release() async {
    ++_generation;
    await _disposeController();
  }

  Future<void> suspend() async {
    if (mounted) state = const CameraIdle();
    await release();
  }

  Future<void> reinitialize(List<cam.CameraDescription> cameras) =>
      initialize(cameras);
  Future<void> _disposeController() {
    final old = _controller;
    _controller = null;
    _closing = _closing.then((_) async {
      try {
        await old?.dispose();
      } catch (error, stack) {
        AppLogger.error(
          'İşlem başarısız.',
          tag: 'camera_provider',
          error: error.runtimeType,
          stackTrace: stack,
        ); /* A disconnected camera may already be disposed. */
      }
    });
    return _closing;
  }

  @override
  void dispose() {
    ++_generation;
    unawaited(_disposeController());
    super.dispose();
  }
}

final cameraProvider =
    StateNotifierProvider.autoDispose<CameraNotifier, CameraState>(
  (ref) => CameraNotifier(),
);
