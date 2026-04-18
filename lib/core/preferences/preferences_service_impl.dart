import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:skeleton/core/preferences/preferences_service.dart';

/// [SharedPreferencesAsync]-backed implementation of
/// [PreferencesService].
@LazySingleton(as: PreferencesService)
class PreferencesServiceImpl implements PreferencesService {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<bool?> getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  @override
  Future<String?> getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, {required String value}) =>
      _prefs.setString(key, value);

  @override
  Future<int?> getInt(String key) => _prefs.getInt(key);

  @override
  Future<void> setInt(String key, {required int value}) =>
      _prefs.setInt(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}
