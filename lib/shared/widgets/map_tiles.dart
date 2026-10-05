import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Retain the existing OSM raster tiles and their readable luminance. Only
/// saturation is reduced (55%); labels, roads and attribution are not dimmed.
Widget mapTileBuilder(BuildContext context, Widget tile, TileImage image) =>
    ColorFiltered(
      colorFilter: const ColorFilter.matrix([
        .64567,
        .32184,
        .03249,
        0,
        0,
        .09567,
        .87184,
        .03249,
        0,
        0,
        .09567,
        .32184,
        .58249,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: tile,
    );
