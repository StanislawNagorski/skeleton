import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class RiveDemoPage extends StatelessWidget {
  const RiveDemoPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('RIVE Demo — built in Plan 03')),
      );
}
