import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'package:skeleton/core/auth/auth_service.dart';
import 'package:skeleton/core/router/guards/auth_guard.dart';
import 'package:skeleton/features/home_page/presentation/home_page.dart';
import 'package:skeleton/features/login/presentation/login_page.dart';

part 'router.gr.dart';

@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter(this._authService);

  final AuthService _authService;

  @override
  late final List<AutoRouteGuard> guards = [
    AuthGuard(_authService),
  ];

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: MyHomeRoute.page, path: '/'),
        AutoRoute(page: LoginRoute.page, path: '/login'),
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
