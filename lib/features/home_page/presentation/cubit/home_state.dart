part of 'home_cubit.dart';

class HomeState {
  const HomeState({required this.counter});

  factory HomeState.initial() => HomeState(
    counter: 0,
  );

  final int counter;

}

