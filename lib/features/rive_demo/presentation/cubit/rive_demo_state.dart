part of 'rive_demo_cubit.dart';

class RiveDemoState {
  const RiveDemoState({
    required this.isToggled,
    required this.status,
  });

  factory RiveDemoState.initial() => const RiveDemoState(
        isToggled: false,
        status: RiveDemoPageStatus.initial,
      );

  final bool isToggled;
  final RiveDemoPageStatus status;

  RiveDemoState copyWith({
    bool? isToggled,
    RiveDemoPageStatus? status,
  }) {
    return RiveDemoState(
      isToggled: isToggled ?? this.isToggled,
      status: status ?? this.status,
    );
  }
}

enum RiveDemoPageStatus {
  initial,
  loaded,
  error,
}
