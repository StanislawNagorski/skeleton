part of 'onboarding_cubit.dart';

class OnboardingState {
  const OnboardingState({
    required this.currentPage,
    required this.totalPages,
    required this.status,
  });

  factory OnboardingState.initial() => const OnboardingState(
        currentPage: 0,
        totalPages: 3,
        status: OnboardingPageStatus.inProgress,
      );

  final int currentPage;
  final int totalPages;
  final OnboardingPageStatus status;

  bool get isLastPage => currentPage == totalPages - 1;

  OnboardingState copyWith({
    int? currentPage,
    int? totalPages,
    OnboardingPageStatus? status,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      status: status ?? this.status,
    );
  }
}

enum OnboardingPageStatus {
  inProgress,
  completed,
}
