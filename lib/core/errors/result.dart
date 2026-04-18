import 'package:skeleton/core/errors/failures.dart';

/// Sealed result type for error handling.
///
/// Use exhaustive `switch` pattern matching to consume:
/// ```dart
/// switch (result) {
///   case Success(:final value): // handle success
///   case Failure(:final failure): // handle failure
/// }
/// ```
sealed class Result<T> {
  const Result();
}

/// Successful result containing [value].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// Failed result containing an [AppFailure].
final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;
}

/// Convenience extensions on [Result].
extension ResultX<T> on Result<T> {
  /// Whether this result is a [Success].
  bool get isSuccess => this is Success<T>;

  /// The success value, or `null` if this is a [Failure].
  T? get valueOrNull => switch (this) {
        Success(:final value) => value,
        Failure() => null,
      };

  /// The failure, or `null` if this is a [Success].
  AppFailure? get failureOrNull => switch (this) {
        Success() => null,
        Failure(:final failure) => failure,
      };
}
