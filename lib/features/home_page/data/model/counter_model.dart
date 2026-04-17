class CounterModel {
  CounterModel({required this.value, this.id = 0});

  final int id;
  final int value;

  CounterModel copyWith({
    int? id,
    int? value,
  }) =>
      CounterModel(
        id: id ?? this.id,
        value: value ?? this.value,
      );
}
