import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Secure storage service for sensitive data
/// 
/// Provides encrypted key-value storage using platform secure storage:
/// - iOS: Keychain
/// - Android: EncryptedSharedPreferences
/// - Web: Not available (throws exception)
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Save a value securely
  Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
      debugPrint('[SecureStorage] Saved: $key');
    } catch (e) {
      debugPrint('[SecureStorage] Failed to save $key: $e');
      rethrow;
    }
  }

  /// Read a value securely
  Future<String?> read({required String key}) async {
    try {
      final value = await _storage.read(key: key);
      debugPrint('[SecureStorage] Read: $key (${value != null ? 'found' : 'not found'})');
      return value;
    } catch (e) {
      debugPrint('[SecureStorage] Failed to read $key: $e');
      return null;
    }
  }

  /// Delete a value
  Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
      debugPrint('[SecureStorage] Deleted: $key');
    } catch (e) {
      debugPrint('[SecureStorage] Failed to delete $key: $e');
      rethrow;
    }
  }

  /// Delete all values
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      debugPrint('[SecureStorage] All data cleared');
    } catch (e) {
      debugPrint('[SecureStorage] Failed to clear all data: $e');
      rethrow;
    }
  }

  /// Check if a key exists
  Future<bool> containsKey({required String key}) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      debugPrint('[SecureStorage] Failed to check key $key: $e');
      return false;
    }
  }

  /// Get all keys
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      debugPrint('[SecureStorage] Failed to read all: $e');
      return {};
    }
  }

  // Common use cases

  /// Save authentication token
  Future<void> saveAuthToken(String token) async {
    await write(key: 'auth_token', value: token);
  }

  /// Read authentication token
  Future<String?> getAuthToken() async {
    return read(key: 'auth_token');
  }

  /// Delete authentication token
  Future<void> deleteAuthToken() async {
    await delete(key: 'auth_token');
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await write(key: 'refresh_token', value: token);
  }

  /// Read refresh token
  Future<String?> getRefreshToken() async {
    return read(key: 'refresh_token');
  }

  /// Save user credentials (only use if absolutely necessary)
  Future<void> saveCredentials({
    required String username,
    required String password,
  }) async {
    await write(key: 'username', value: username);
    await write(key: 'password', value: password);
  }

  /// Read user credentials
  Future<Map<String, String?>> getCredentials() async {
    return {
      'username': await read(key: 'username'),
      'password': await read(key: 'password'),
    };
  }

  /// Clear all credentials and tokens
  Future<void> clearAllCredentials() async {
    await delete(key: 'auth_token');
    await delete(key: 'refresh_token');
    await delete(key: 'username');
    await delete(key: 'password');
  }
}
