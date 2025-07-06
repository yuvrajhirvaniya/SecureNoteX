import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'secure_storage_service.dart';

/// Service for handling AES 256-bit encryption and decryption
/// Uses CBC mode with PKCS7 padding for maximum security
class EncryptionService {
  static const String _keyStorageKey = 'aes_encryption_key';
  static const String _ivStorageKey = 'aes_iv_key';
  
  final SecureStorageService _secureStorage;
  Encrypter? _encrypter;
  IV? _iv;
  
  EncryptionService(this._secureStorage);

  /// Initialize the encryption service
  /// Generates or retrieves the AES key and IV from secure storage
  Future<void> initialize() async {
    try {
      // Get or generate encryption key
      String? keyString = await _secureStorage.read(_keyStorageKey);
      Key key;
      
      if (keyString == null) {
        // Generate new 256-bit (32 bytes) AES key
        key = _generateSecureKey();
        await _secureStorage.write(_keyStorageKey, key.base64);
      } else {
        key = Key.fromBase64(keyString);
      }

      // Get or generate IV (Initialization Vector)
      String? ivString = await _secureStorage.read(_ivStorageKey);
      if (ivString == null) {
        // Generate new 128-bit (16 bytes) IV
        _iv = _generateSecureIV();
        await _secureStorage.write(_ivStorageKey, _iv!.base64);
      } else {
        _iv = IV.fromBase64(ivString);
      }

      // Initialize encrypter with AES algorithm in CBC mode
      _encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
      
    } catch (e) {
      throw Exception('Failed to initialize encryption service: $e');
    }
  }

  /// Encrypt a plain text string using AES 256-bit encryption
  /// Returns base64 encoded encrypted string
  String encrypt(String plainText) {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypted = _encrypter!.encrypt(plainText, iv: _iv!);
      return encrypted.base64;
    } catch (e) {
      throw Exception('Failed to encrypt data: $e');
    }
  }

  /// Decrypt an encrypted string back to plain text
  /// Takes base64 encoded encrypted string as input
  String decrypt(String encryptedText) {
    if (_encrypter == null || _iv == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      return _encrypter!.decrypt(encrypted, iv: _iv!);
    } catch (e) {
      throw Exception('Failed to decrypt data: $e');
    }
  }

  /// Encrypt a Map object (useful for JSON data)
  /// Converts map to JSON string, then encrypts it
  String encryptMap(Map<String, dynamic> data) {
    final jsonString = jsonEncode(data);
    return encrypt(jsonString);
  }

  /// Decrypt to a Map object
  /// Decrypts string and converts back to Map
  Map<String, dynamic> decryptToMap(String encryptedText) {
    final decryptedString = decrypt(encryptedText);
    return jsonDecode(decryptedString) as Map<String, dynamic>;
  }

  /// Generate a cryptographically secure 256-bit AES key
  Key _generateSecureKey() {
    final random = Random.secure();
    final keyBytes = Uint8List(32); // 256 bits = 32 bytes
    
    for (int i = 0; i < keyBytes.length; i++) {
      keyBytes[i] = random.nextInt(256);
    }
    
    return Key(keyBytes);
  }

  /// Generate a cryptographically secure 128-bit IV
  IV _generateSecureIV() {
    final random = Random.secure();
    final ivBytes = Uint8List(16); // 128 bits = 16 bytes
    
    for (int i = 0; i < ivBytes.length; i++) {
      ivBytes[i] = random.nextInt(256);
    }
    
    return IV(ivBytes);
  }

  /// Generate a hash of the input string using SHA-256
  /// Useful for creating consistent identifiers or checksums
  String generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify if the encryption service is properly initialized
  bool get isInitialized => _encrypter != null && _iv != null;

  /// Reset the encryption service (for logout or key rotation)
  Future<void> reset() async {
    await _secureStorage.delete(_keyStorageKey);
    await _secureStorage.delete(_ivStorageKey);
    _encrypter = null;
    _iv = null;
  }
}
