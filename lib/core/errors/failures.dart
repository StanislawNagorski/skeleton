class Failure {
  const Failure(this.message);

  factory Failure.localDataNotFound(String? message) => LocalDataNotFoundFailure(message);
  factory Failure.localDataSource(String? message) => LocalDataSourceFailure(message);

  final String? message;
}

class LocalDataNotFoundFailure extends Failure {
  const LocalDataNotFoundFailure(super.message);
}

class LocalDataSourceFailure extends Failure {
  const LocalDataSourceFailure(super.message);
}