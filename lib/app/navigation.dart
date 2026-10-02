import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

final appRouteObserver = RouteObserver<PageRoute<dynamic>>();
