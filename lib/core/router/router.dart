import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:skeleton/features/home_page/presentation/home_page.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  final List<AutoRoute> routes = [
    AutoRoute(page: MyHomeRoute.page, path: '/'),
  ];
}

class AppRouterObserver extends AutoRouterObserver {
  final Logger logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      noBoxingByDefault: true,
    ),
  );

  void logRouteChange(
    Object classOfOrigin, {
    required Route<dynamic> route,
    Route<dynamic>? previousRoute,
  }) {
    final routeName = route.settings.name ?? 'unknown';
    final previousRouteName =
        previousRoute?.settings.name ?? 'unknown';
    final routeChangeMessage =
        'previousRoute $previousRouteName '
        'and current: $routeName';
    logger.t(
      '${classOfOrigin.runtimeType}: $routeChangeMessage',
    );
  }

  @override
  void didPush(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) =>
      logRouteChange(
        this,
        route: route,
        previousRoute: previousRoute,
      );

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) =>
      logRouteChange(
        this,
        route: route,
        previousRoute: previousRoute,
      );

  @override
  void didRemove(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) =>
      logRouteChange(
        this,
        route: route,
        previousRoute: previousRoute,
      );

  @override
  void didPop(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) =>
      logRouteChange(
        this,
        route: route,
        previousRoute: previousRoute,
      );
}
