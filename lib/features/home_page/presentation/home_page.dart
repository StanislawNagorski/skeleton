import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skeleton/core/coach_mark/coach_mark_service.dart';
import 'package:skeleton/core/extensions/context_extension.dart';
import 'package:skeleton/core/injectable/injection.dart';
import 'package:skeleton/core/presentation/app_dimensions.dart';
import 'package:skeleton/core/router/router.dart';
import 'package:skeleton/features/home_page/presentation/cubit/home_cubit.dart';

@RoutePage()
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        // ignore: discarded_futures -- init is fire-and-forget by design
        create: (context) => getIt<HomeCubit>()..init(),
        child: Builder(
          builder: (context) => BlocListener<HomeCubit, HomeState>(
            listener: (context, state) {
              switch (state.status) {
                case HomePageStatus.loading:
                  _showLoadingSnackBar(context);
                case HomePageStatus.success:
                case HomePageStatus.empty:
                  break;
                case HomePageStatus.error:
                  _showErrorSnackBar(context);
              }
            },
            child: const _Page(),
          ),
        ),
      );

  void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.localizations.homePage_error),
        backgroundColor: context.theme.colorScheme.error,
      ),
    );
  }

  void _showLoadingSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            CircularProgressIndicator(),
          ],
        ),
        backgroundColor: context.theme.colorScheme.primary,
      ),
    );
  }
}

class _Page extends StatefulWidget {
  const _Page();

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  final GlobalKey _counterKey = GlobalKey();
  final GlobalKey _fabKey = GlobalKey();

  late final CoachMarkService _coachMarkService;

  @override
  void initState() {
    super.initState();
    _coachMarkService = getIt<CoachMarkService>();

    // Register coach mark targets (D-14: counter display + FAB).
    _coachMarkService
      ..register(
        'home',
        _counterKey,
        // Hardcoded strings -- context is not available in initState.
        // Downstream apps can localize via didChangeDependencies.
        'Tap the button below to increment it.',
        title: 'This is your counter',
      )
      ..register(
        'home',
        _fabKey,
        'Tap this button to increase the counter.',
        title: 'Increment',
      );

    // Auto-fire tour on first visit (D-13).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // ignore: discarded_futures
        _coachMarkService.showTour('home', context);
      }
    });
  }

  @override
  void dispose() {
    _coachMarkService.unregister('home');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: context.theme.colorScheme.inversePrimary,
          title: Text(context.localizations.homePage_title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                context.localizations.homePage_centeredText,
              ),
              BlocBuilder<HomeCubit, HomeState>(
                buildWhen: (previous, current) =>
                    previous.counter.value != current.counter.value,
                builder: (context, state) => Text(
                  '${state.counter.value}',
                  key: _counterKey,
                  style: context.theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLarge),
              // RIVE Demo navigation button (per D-16).
              OutlinedButton.icon(
                onPressed: () =>
                    context.router.push(const RiveDemoRoute()),
                icon: const Icon(Icons.animation),
                label: Text(
                  context.localizations.homePage_riveDemoButton,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              key: _fabKey,
              onPressed: context.read<HomeCubit>().increment,
              tooltip:
                  context.localizations.homePage_incrementButton,
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: AppDimensions.spacingBase),
            FloatingActionButton(
              onPressed: context.read<HomeCubit>().decrement,
              tooltip:
                  context.localizations.homePage_decrementButton,
              child: const Icon(Icons.remove),
            ),
          ],
        ),
      );
}
