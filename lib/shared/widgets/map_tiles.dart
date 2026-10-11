import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Soft daylight treatment retaining the OSM provider and attribution.
/// Reducing saturation and lifting shadows keeps roads readable beside warm UI.
/// Alpha is preserved so tiles still compose normally while loading.
Widget mapTileBuilder(BuildContext context, Widget tile, TileImage image) =>
    ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        .55,
        .16,
        .05,
        0,
        48,
        .11,
        .60,
        .05,
        0,
        46,
        .10,
        .22,
        .38,
        0,
        55,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: tile,
    );
