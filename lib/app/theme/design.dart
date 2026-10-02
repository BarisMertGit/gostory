import 'package:flutter/material.dart';

abstract final class AppRadii {
  static const control = 14.0;
  static const card = 20.0;
  static const sheet = 28.0;
}

abstract final class AppMotion {
  static Duration duration(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200);
}
