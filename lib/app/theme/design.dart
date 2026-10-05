import 'package:flutter/material.dart';

abstract final class AppRadii {
  static const small = 12.0;
  static const control = 14.0;
  static const card = 20.0;
  static const sheet = 28.0;
}

abstract final class AppSizes {
  static const touchTarget = 44.0;
  static const navigation = 64.0;
  static const avatar = 68.0;
  static const marker = 38.0;
  static const selectedMarker = 42.0;
}

abstract final class AppMotion {
  static const standard = Duration(milliseconds: 200);

  static Duration duration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : standard;
}
