import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/notifications/domain/push_destination.dart';
import 'app_routes.dart';

/// Where a tapped push notification goes. The server sends one of a fixed
/// list of destinations; anything unknown or incomplete opens Home.
abstract final class PushRoutes {
  static void open(BuildContext context, PushDestination destination) {
    final router = GoRouter.of(context);
    final id = destination.id;
    switch (destination.kind) {
      case PushDestinationKind.home:
        router.go(AppRoutes.map);
      case PushDestinationKind.explore:
        router.go(AppRoutes.explore);
      case PushDestinationKind.badges:
        router.go(AppRoutes.badges);
      case PushDestinationKind.profile:
        unawaited(router.push<void>(AppRoutes.profile));
      case PushDestinationKind.myPhotos:
        unawaited(router.push<void>(AppRoutes.myPhotos));
      case PushDestinationKind.county:
        final code = id == null ? null : int.tryParse(id);
        if (code == null) {
          router.go(AppRoutes.map);
        } else {
          unawaited(router.push<void>(AppRoutes.county(code)));
        }
      case PushDestinationKind.place:
        if (id == null) {
          router.go(AppRoutes.map);
        } else {
          unawaited(router.push<void>(AppRoutes.place(id)));
        }
    }
  }
}
