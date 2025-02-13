part of 'home_cubit.dart';

class HomeState {
  const HomeState({
    required this.navigation,
    required this.status,
    required this.counter,
  });

  factory HomeState.initial() => HomeState(
        status: HomePageStatus.empty,
        navigation: HomePageNavigation.empty,
        counter: CounterModel(value: 0),
      );

  final CounterModel counter;
  final HomePageStatus status;
  final HomePageNavigation navigation;

  HomeState copyWith({
    HomePageStatus? status,
    HomePageNavigation? navigation,
    CounterModel? counter,
  }) {
    return HomeState(
      status: status ?? this.status,
      navigation: navigation ?? this.navigation,
      counter: counter ?? this.counter,
    );
  }
}

enum HomePageStatus {
  loading,
  success,
  error,
  empty,
}

enum HomePageNavigation {
  empty,
}
