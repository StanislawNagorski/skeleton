import 'package:objectbox/objectbox.dart';

@Entity()
class CounterModel {
  CounterModel({this.id = 0, required this.value});

  @Id()
  int id;
  final int value;

  CounterModel copyWith({
    int? id,
    int? value,
  }) => CounterModel(
      id: id ?? this.id,
      value: value ?? this.value,
    );

}