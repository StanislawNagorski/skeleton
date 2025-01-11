
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeState.initial());

  void increment() {
    emit(HomeState(counter: state.counter + 1));
  }

}
