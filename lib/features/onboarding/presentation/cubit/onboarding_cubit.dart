import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'package:skeleton/app.dart';
import 'package:skeleton/core/preferences/preferences_keys.dart';
import 'package:skeleton/core/preferences/preferences_service.dart';
import 'package:skeleton/core/router/guards/onboarding_guard.dart';

part 'onboarding_state.dart';

/// Manages onboarding slide navigation and `hasSeenOnboarding` persistence.
@injectable
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(
    this._preferencesService,
    this._onboardingGuard,
  ) : super(OnboardingState.initial());

  final PreferencesService _preferencesService;
  final OnboardingGuard _onboardingGuard;

  /// Advances to the next slide if not on the last page.
  void nextPage() {
    if (!state.isLastPage) {
      emit(state.copyWith(currentPage: state.currentPage + 1));
    }
  }

  /// Updates the current page index (called by PageView onPageChanged).
  void onPageChanged(int page) {
    emit(state.copyWith(currentPage: page));
  }

  /// Completes onboarding: persists the flag, updates the guard,
  /// and fires the re-evaluation notifier.
  Future<void> completeOnboarding() async {
    await _preferencesService.setBool(
      PreferencesKeys.hasSeenOnboarding,
      value: true,
    );
    _onboardingGuard.markOnboardingSeen();
    // Trigger router guard re-evaluation so OnboardingGuard
    // passes and the router navigates to HomeRoute.
    MyApp.onboardingNotifier.value = !MyApp.onboardingNotifier.value;
    emit(state.copyWith(status: OnboardingPageStatus.completed));
  }

  /// Skip = complete immediately (per D-09).
  Future<void> skipOnboarding() => completeOnboarding();
}
