/// Sealed failure hierarchy for typed error classification.
///
/// Phase 2 ships [LocalDataNotFound] + [LocalDataSource].
/// Phase 3 adds auth failures, Phase 5 adds network/Firebase failures.
sealed class AppFailure {
  const AppFailure(this.message);

  final String message;
}

/// Data was not found in local storage.
final class LocalDataNotFound extends AppFailure {
  const LocalDataNotFound(super.message);
}

/// Local data source operation failed.
final class LocalDataSource extends AppFailure {
  const LocalDataSource(super.message);
}

/// Authentication operation failed.
final class AuthError extends AppFailure {
  const AuthError(super.message);
}
