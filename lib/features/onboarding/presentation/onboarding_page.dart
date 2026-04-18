import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:skeleton/core/extensions/context_extension.dart';
import 'package:skeleton/core/injectable/injection.dart';
import 'package:skeleton/core/presentation/app_dimensions.dart';
import 'package:skeleton/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:skeleton/features/onboarding/presentation/widgets/dot_indicator.dart';
import 'package:skeleton/features/onboarding/presentation/widgets/onboarding_slide.dart';

@RoutePage()
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (context) => getIt<OnboardingCubit>(),
        child: const _Page(),
      );
}

class _Page extends StatefulWidget {
  const _Page();

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop &&
            _pageController.page != null &&
            _pageController.page! > 0) {
          // ignore: discarded_futures -- fire-and-forget animation
          _pageController.previousPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      },
      child: Scaffold(
        backgroundColor: context.theme.colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // Skip button top-right (per D-09)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding:
                      const EdgeInsets.all(AppDimensions.spacingMedium),
                  child: Semantics(
                    label: 'Skip onboarding',
                    child: TextButton(
                      onPressed: cubit.skipOnboarding,
                      child: Text(
                        context.localizations.onboarding_skipButton,
                        style: TextStyle(
                          color:
                              context.theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // PageView with 3 slides (per D-07, D-08)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(),
                  onPageChanged: cubit.onPageChanged,
                  children: [
                    OnboardingSlide(
                      imagePath: 'assets/images/onboarding/slide_1.webp',
                      title:
                          context.localizations.onboarding_slide1Title,
                      subtitle: context
                          .localizations.onboarding_slide1Subtitle,
                    ),
                    OnboardingSlide(
                      imagePath: 'assets/images/onboarding/slide_2.webp',
                      title:
                          context.localizations.onboarding_slide2Title,
                      subtitle: context
                          .localizations.onboarding_slide2Subtitle,
                    ),
                    OnboardingSlide(
                      imagePath: 'assets/images/onboarding/slide_3.webp',
                      title:
                          context.localizations.onboarding_slide3Title,
                      subtitle: context
                          .localizations.onboarding_slide3Subtitle,
                    ),
                  ],
                ),
              ),
              // Dot indicator + button (per D-10)
              BlocBuilder<OnboardingCubit, OnboardingState>(
                builder: (context, state) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spacingExtraLarge,
                  ),
                  child: Column(
                    children: [
                      DotIndicator(
                        count: state.totalPages,
                        currentIndex: state.currentPage,
                      ),
                      const SizedBox(height: AppDimensions.spacingLarge),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton(
                          onPressed: state.isLastPage
                              ? cubit.completeOnboarding
                              : () {
                                  cubit.nextPage();
                                  // ignore: discarded_futures
                                  _pageController.nextPage(
                                    duration: const Duration(
                                      milliseconds: 300,
                                    ),
                                    curve: Curves.easeInOut,
                                  );
                                },
                          child: Text(
                            state.isLastPage
                                ? context.localizations
                                    .onboarding_getStartedButton
                                : context.localizations
                                    .onboarding_nextButton,
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: AppDimensions.spacingXXXL,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
