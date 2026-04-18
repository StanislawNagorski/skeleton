import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

/// Placeholder login page -- replaced per app.
///
/// The skeleton does not ship login UI (out of scope). This page exists
/// solely as the `AuthGuard` redirect target so routing is testable.
@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Text('Login screen — built per app'),
        ),
      );
}
