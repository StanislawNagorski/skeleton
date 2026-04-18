import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rive/rive.dart';

import 'package:skeleton/core/extensions/context_extension.dart';
import 'package:skeleton/core/injectable/injection.dart';
import 'package:skeleton/core/presentation/app_dimensions.dart';
import 'package:skeleton/features/rive_demo/presentation/cubit/rive_demo_cubit.dart';

/// Dedicated RIVE demo page showcasing .riv asset loading,
/// state-machine interaction, and proper cleanup (D-16, D-17).
@RoutePage()
class RiveDemoPage extends StatelessWidget {
  const RiveDemoPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => getIt<RiveDemoCubit>(),
        child: const _Page(),
      );
}

class _Page extends StatefulWidget {
  const _Page();

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  late final FileLoader _fileLoader;

  @override
  void initState() {
    super.initState();
    _fileLoader = FileLoader.fromAsset(
      'assets/rive/demo.riv',
      riveFactory: Factory.rive,
    );
  }

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          backgroundColor: context.theme.colorScheme.inversePrimary,
          title: Text(context.localizations.riveDemo_title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingMedium),
          child: Column(
            children: [
              // Animation canvas in a Card (300px height, 12px radius).
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: RiveWidgetBuilder(
                    fileLoader: _fileLoader,
                    onLoaded: (_) =>
                        context.read<RiveDemoCubit>().onLoaded(),
                    onFailed: (_, __) =>
                        context.read<RiveDemoCubit>().onLoadFailed(),
                    builder: (context, state) => switch (state) {
                      RiveLoading() => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      RiveFailed() => Center(
                          child: Text(
                            context.localizations.riveDemo_animationLoadError(
                              state.error,
                            ),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      RiveLoaded() =>
                        RiveWidget(controller: state.controller),
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              // Description text.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingMedium,
                ),
                child: Text(
                  context.localizations.riveDemo_description,
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    color: context.theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
