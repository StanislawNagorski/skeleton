import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'rive_demo_state.dart';

/// Manages RIVE demo page toggle state.
///
/// The cubit tracks the boolean toggle value. The actual RIVE
/// state-machine input is managed in the page's StatefulWidget
/// because RIVE controllers are tied to the render tree and must
/// be disposed in `State.dispose`, not in the cubit.
@injectable
class RiveDemoCubit extends Cubit<RiveDemoState> {
  RiveDemoCubit() : super(RiveDemoState.initial());

  /// Toggles the animation state-machine boolean input.
  void toggleAnimation() {
    emit(state.copyWith(isToggled: !state.isToggled));
  }

  /// Called when the RIVE file loads successfully.
  void onLoaded() {
    emit(state.copyWith(status: RiveDemoPageStatus.loaded));
  }

  /// Called when the RIVE file fails to load.
  void onError() {
    emit(state.copyWith(status: RiveDemoPageStatus.error));
  }
}
