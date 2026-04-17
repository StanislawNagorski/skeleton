/// Abstract secure storage service for encrypted key-value
/// persistence.
///
/// Use for token-class data: auth tokens, refresh tokens, API keys.
/// Do NOT use for non-sensitive preferences -- use
/// `PreferencesService` instead.
abstract class SecureStorageService {
  /// Reads the encrypted value for [key], or `null` if not set.
  Future<String?> read({required String key});

  /// Writes an encrypted [value] for [key].
  Future<void> write({required String key, required String value});

  /// Deletes the encrypted value for [key].
  Future<void> delete({required String key});

  /// Deletes all stored encrypted values.
  Future<void> deleteAll();
}
