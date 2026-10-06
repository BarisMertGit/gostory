import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../core/services/photo_cache.dart';
import '../../core/widgets/demo_scene.dart';

/// Shared rendering for archive photos and bundled demo placeholders.
class MemoryPhoto extends StatelessWidget {
  const MemoryPhoto({super.key, required this.path, this.height, this.width});
  final String path;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final loading = Semantics(
      label: 'Fotoğraf yükleniyor',
      child: SizedBox(
        width: width,
        height: height,
        child: const ColoredBox(color: AppColors.surfaceVariant),
      ),
    );
    final fallback = SizedBox(
      height: height,
      width: width,
      child: const ColoredBox(
        color: Color(0xFF304144),
        child: Center(
          child: Icon(
            Icons.landscape_outlined,
            size: 40,
            semanticLabel: 'Fotoğraf mevcut değil',
          ),
        ),
      ),
    );
    if (path.startsWith('demo://')) {
      return SizedBox(
        height: height,
        width: width,
        child: const ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 400,
              height: 300,
              child: DemoScene(),
            ),
          ),
        ),
      );
    }
    if (path.isEmpty) return fallback;
    if (path.startsWith('storage://')) {
      return FutureBuilder<Uint8List?>(
        future: PhotoCache.load(path.substring(10)),
        builder: (context, snapshot) => snapshot.hasData
            ? Image.memory(
                snapshot.data!,
                cacheWidth: 1600,
                height: height,
                width: width,
                fit: BoxFit.cover,
                semanticLabel: 'Anı fotoğrafı',
              )
            : snapshot.connectionState == ConnectionState.waiting
                ? loading
                : fallback,
      );
    }
    if (path.startsWith('https://')) {
      return Semantics(
        image: true,
        label: 'Anı fotoğrafı',
        child: CachedNetworkImage(
          imageUrl: path,
          height: height,
          width: width,
          fit: BoxFit.cover,
          memCacheWidth: 1600,
          errorWidget: (_, __, ___) => fallback,
          placeholder: (_, __) => loading,
        ),
      );
    }
    final ImageProvider image = path.startsWith('assets/')
        ? AssetImage(path)
        : path.startsWith('https://') || path.startsWith('http://')
            ? NetworkImage(path)
            : FileImage(File(path));
    return Image(
      image: image,
      height: height,
      width: width,
      fit: BoxFit.cover,
      semanticLabel: 'Anı fotoğrafı',
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

/// Explicit source tags avoid collisions between map and profile photographs.
class MemoryPhotoTransition extends StatelessWidget {
  const MemoryPhotoTransition({super.key, required this.child, this.tag});
  final Object? tag;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      tag == null || MediaQuery.disableAnimationsOf(context)
          ? child
          : Hero(
              tag: tag!,
              flightShuttleBuilder: (_, __, ___, from, to) => DefaultTextStyle(
                style: DefaultTextStyle.of(to).style,
                child: (to.widget as Hero).child,
              ),
              child: child,
            );
}
