import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../../features/home_page/presentation/home_page.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  @override
  final List<AutoRoute> routes = [
    AutoRoute(page:MyHomeRoute.page,  path: '/'),
  ];
}

class AppRouterObserver extends AutoRouterObserver {
  final logger = Logger(printer: PrettyPrinter(methodCount: 2));

  void logRouteChange(classOfOrigin, {required Route route, Route? previousRoute}) {
    final routeName = route.settings.name ?? 'unknown';
    final previousRouteName = previousRoute?.settings.name ?? 'unknown';
    final routeChangeMessage = 'previousRoute $previousRouteName and current: $routeName';
    logger.t('${classOfOrigin.runtimeType}: $routeChangeMessage}');
  }

  @override
  void didPush(Route route, Route? previousRoute) => logRouteChange(route: route, previousRoute: previousRoute, this);

  @override
  void didStartUserGesture(Route route, Route? previousRoute) =>
      logRouteChange(route: route, previousRoute: previousRoute, this);

  @override
  void didRemove(Route route, Route? previousRoute) => logRouteChange(route: route, previousRoute: previousRoute, this);

  @override
  void didPop(Route route, Route? previousRoute) => logRouteChange(route: route, previousRoute: previousRoute, this);
}
