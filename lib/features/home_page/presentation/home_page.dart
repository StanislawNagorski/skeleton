import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:skeleton/core/extensions/context_extension.dart';

import '../../../core/injectable/injection.dart';
import '../../../core/presentation/app_dimensions.dart';
import 'cubit/home_cubit.dart';

@RoutePage()
class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => getIt<HomeCubit>()..init(),
        child: Builder(
          builder: (context) => BlocListener<HomeCubit, HomeState>(
            listener: (context, state) {
              switch (state.status) {
                case HomePageStatus.loading:
                  _showLoadingSnackBar(context);
                  break;
                case HomePageStatus.success:
                  break;
                case HomePageStatus.error:
                  _showErrorSnackBar(context);
                  break;
                case HomePageStatus.empty:
                  break;
              }
            },
            child: _Page(),
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
        content: Row(
          children: [
            CircularProgressIndicator(),
          ],
        ),
        backgroundColor: context.theme.colorScheme.primary,
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page();

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
              Text(context.localizations.homePage_centeredText),
              BlocBuilder<HomeCubit, HomeState>(
                buildWhen: (previous, current) => previous.counter.value != current.counter.value,
                builder: (context, state) => Text(
                  '${state.counter.value}',
                  style: context.theme.textTheme.headlineMedium,
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: context.read<HomeCubit>().increment,
              tooltip: context.localizations.homePage_incrementButton,
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: AppDimensions.spacingBase),
            FloatingActionButton(
              onPressed: context.read<HomeCubit>().decrement,
              tooltip: context.localizations.homePage_decrementButton,
              child: const Icon(Icons.remove),
            ),
          ],
        ),
      );
}
