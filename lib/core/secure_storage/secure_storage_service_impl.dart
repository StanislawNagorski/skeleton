import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:skeleton/core/secure_storage/secure_storage_service.dart';

/// [FlutterSecureStorage]-backed implementation of
/// [SecureStorageService].
///
/// Android: uses custom ciphers (default since flutter_secure_storage
/// v10).
/// iOS: uses Keychain with `first_unlock_this_device` accessibility.
@LazySingleton(as: SecureStorageService)
class SecureStorageServiceImpl implements SecureStorageService {
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility:
          KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read({required String key}) =>
      _storage.read(key: key);

  @override
  Future<void> write({
    required String key,
    required String value,
  }) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) =>
      _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
