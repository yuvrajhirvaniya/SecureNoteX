import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive data using flutter_secure_storage
/// This service handles encryption keys, user preferences, and other sensitive configuration
class SecureStorageService {
  static const String _authStateKey = 'auth_state';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _lastAuthTimeKey = 'last_auth_time';
  static const String _appVersionKey = 'app_version';

  // Configure secure storage with additional security options
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // Encrypt the shared preferences for Android
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      // Use keychain accessibility for iOS
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  /// Write a key-value pair to secure storage
  Future<void> write(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      throw Exception('Failed to write to secure storage: $e');
    }
  }

  /// Read a value from secure storage by key
  Future<String?> read(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      throw Exception('Failed to read from secure storage: $e');
    }
  }

  /// Delete a key-value pair from secure storage
  Future<void> delete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      throw Exception('Failed to delete from secure storage: $e');
    }
  }

  /// Check if a key exists in secure storage
  Future<bool> containsKey(String key) async {
    try {
      return await _secureStorage.containsKey(key: key);
    } catch (e) {
      throw Exception('Failed to check key existence: $e');
    }
  }

  /// Get all keys from secure storage
  Future<Map<String, String>> readAll() async {
    try {
      return await _secureStorage.readAll();
    } catch (e) {
      throw Exception('Failed to read all from secure storage: $e');
    }
  }

  /// Clear all data from secure storage
  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      throw Exception('Failed to clear secure storage: $e');
    }
  }

  // Authentication-related storage methods

  /// Save authentication state
  Future<void> saveAuthState(bool isAuthenticated) async {
    await write(_authStateKey, isAuthenticated.toString());
  }

  /// Get authentication state
  Future<bool> getAuthState() async {
    final value = await read(_authStateKey);
    return value?.toLowerCase() == 'true';
  }

  /// Save biometric enabled preference
  Future<void> setBiometricEnabled(bool enabled) async {
    await write(_biometricEnabledKey, enabled.toString());
  }

  /// Get biometric enabled preference
  Future<bool> isBiometricEnabled() async {
    final value = await read(_biometricEnabledKey);
    return value?.toLowerCase() == 'true';
  }

  /// Save last authentication timestamp
  Future<void> saveLastAuthTime() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await write(_lastAuthTimeKey, timestamp);
  }

  /// Get last authentication timestamp
  Future<DateTime?> getLastAuthTime() async {
    final value = await read(_lastAuthTimeKey);
    if (value != null) {
      final timestamp = int.tryParse(value);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
    return null;
  }

  /// Save app version for migration purposes
  Future<void> saveAppVersion(String version) async {
    await write(_appVersionKey, version);
  }

  /// Get saved app version
  Future<String?> getAppVersion() async {
    return await read(_appVersionKey);
  }

  /// Clear authentication-related data (for logout)
  Future<void> clearAuthData() async {
    await delete(_authStateKey);
    await delete(_lastAuthTimeKey);
    // Note: We keep biometric preference and app version
  }

  /// Check if this is the first app launch
  Future<bool> isFirstLaunch() async {
    return !(await containsKey(_appVersionKey));
  }

  /// Migrate data if needed (for app updates)
  Future<void> migrateIfNeeded(String currentVersion) async {
    final savedVersion = await getAppVersion();
    
    if (savedVersion == null) {
      // First launch, save current version
      await saveAppVersion(currentVersion);
      return;
    }

    if (savedVersion != currentVersion) {
      // App was updated, perform migration if needed
      await _performMigration(savedVersion, currentVersion);
      await saveAppVersion(currentVersion);
    }
  }

  /// Perform data migration between app versions
  Future<void> _performMigration(String fromVersion, String toVersion) async {
    // Implement version-specific migration logic here
    // For example:
    // if (fromVersion == '1.0.0' && toVersion == '1.1.0') {
    //   // Perform specific migration
    // }
  }
}
