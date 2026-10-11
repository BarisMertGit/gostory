import 'package:flutter/material.dart';

abstract final class AppRadii {
  static const small = 14.0;
  static const control = 18.0;
  static const card = 24.0;
  static const sheet = 32.0;
}

abstract final class AppSizes {
  static const touchTarget = 44.0;
  static const navigation = 64.0;
  static const avatar = 68.0;
  static const marker = 38.0;
  static const selectedMarker = 42.0;
}

abstract final class AppMotion {
  static const instant = Duration(milliseconds: 100);
  static const standard = Duration(milliseconds: 200);
  static const emphasized = Duration(milliseconds: 350);
  static const slow = Duration(milliseconds: 500);
  static const entrance = Duration(milliseconds: 600);
  static const standardCurve = Curves.easeOutCubic;
  static const emphasizedCurve = Curves.easeOutBack;
  static const bounceCurve = Curves.elasticOut;

  static Duration duration(BuildContext context, [Duration value = standard]) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}
