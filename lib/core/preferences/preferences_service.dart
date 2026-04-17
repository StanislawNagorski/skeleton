/// Abstract preferences service for key-value persistence.
///
/// Features define their own key constants -- this service provides
/// the typed get/set plumbing.
abstract class PreferencesService {
  /// Reads a boolean value for [key], or `null` if not set.
  Future<bool?> getBool(String key);

  /// Writes a boolean [value] for [key].
  Future<void> setBool(String key, {required bool value});

  /// Reads a string value for [key], or `null` if not set.
  Future<String?> getString(String key);

  /// Writes a string [value] for [key].
  Future<void> setString(String key, {required String value});

  /// Reads an integer value for [key], or `null` if not set.
  Future<int?> getInt(String key);

  /// Writes an integer [value] for [key].
  Future<void> setInt(String key, {required int value});

  /// Removes the value for [key].
  Future<void> remove(String key);
}
