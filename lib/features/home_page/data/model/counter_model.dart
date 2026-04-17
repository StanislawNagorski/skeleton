/// Counter value model.
///
/// Plain Dart class -- persistence mapping happens in the data source
/// layer.
class CounterModel {
  const CounterModel({required this.value, this.id = 0});

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
