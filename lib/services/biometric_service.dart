import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import '../models/auth_result.dart';

/// Service for handling biometric authentication using local_auth plugin
/// Supports fingerprint, facial recognition, and other biometric methods
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if biometric authentication is available on the device
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking biometric availability: $e');
      }
      return false;
    }
  }

  /// Get list of available biometric types on the device
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if any biometric credentials are enrolled on the device
  Future<bool> isBiometricEnrolled() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Authenticate user using biometric authentication
  /// Returns AuthResult with success/failure status and type
  Future<AuthResult> authenticateWithBiometrics({
    String localizedReason = 'Please authenticate to access your secure data',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool sensitiveTransaction = false, // Changed to false for better compatibility
  }) async {
    try {
      // Check if biometric authentication is available
      if (!await isBiometricAvailable()) {
        return AuthResult.failure(
          'Biometric authentication is not available on this device',
          AuthResultType.notAvailable,
        );
      }

      // Get available biometrics to check what's actually available
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return AuthResult.failure(
          'No biometric methods are available on this device',
          AuthResultType.notEnrolled,
        );
      }

      // Try authentication with more permissive settings
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          sensitiveTransaction: sensitiveTransaction,
          biometricOnly: false, // Allow fallback to device credentials
        ),
      );

      if (didAuthenticate) {
        return AuthResult.success(AuthResultType.biometric);
      } else {
        return AuthResult.failure(
          'Authentication was cancelled or failed',
          AuthResultType.cancelled,
        );
      }
    } catch (e) {
      return _handleAuthenticationError(e);
    }
  }

  /// Authenticate using only biometric methods (no fallback to device credentials)
  Future<AuthResult> authenticateWithBiometricsOnly({
    String localizedReason = 'Please authenticate using biometrics',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      if (!await isBiometricAvailable()) {
        return AuthResult.failure(
          'Biometric authentication is not available',
          AuthResultType.notAvailable,
        );
      }

      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return AuthResult.failure(
          'No biometric credentials enrolled',
          AuthResultType.notEnrolled,
        );
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true, // Only biometric, no fallback
          sensitiveTransaction: false, // Allow weak biometrics
        ),
      );

      if (didAuthenticate) {
        return AuthResult.success(AuthResultType.biometric);
      } else {
        return AuthResult.failure(
          'Biometric authentication cancelled',
          AuthResultType.cancelled,
        );
      }
    } catch (e) {
      return _handleAuthenticationError(e);
    }
  }

  /// Authenticate with weak biometrics allowed
  Future<AuthResult> authenticateWithWeakBiometrics({
    String localizedReason = 'Please authenticate to access your data',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final availableBiometrics = await getAvailableBiometrics();

      // Check if any biometric method is available (including weak ones)
      if (availableBiometrics.isEmpty) {
        return AuthResult.failure(
          'No biometric authentication methods available',
          AuthResultType.notAvailable,
        );
      }

      // Try authentication with weak biometrics allowed
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: false, // Allow device credentials as fallback
          sensitiveTransaction: false, // Allow weak biometrics
        ),
      );

      if (didAuthenticate) {
        return AuthResult.success(AuthResultType.biometric);
      } else {
        return AuthResult.failure(
          'Authentication cancelled or failed',
          AuthResultType.cancelled,
        );
      }
    } catch (e) {
      return _handleAuthenticationError(e);
    }
  }

  /// Get a user-friendly description of available biometric methods
  Future<String> getBiometricDescription() async {
    try {
      final availableBiometrics = await getAvailableBiometrics();
      
      if (availableBiometrics.isEmpty) {
        return 'No biometric authentication available';
      }

      final List<String> descriptions = [];
      
      for (final biometric in availableBiometrics) {
        switch (biometric) {
          case BiometricType.face:
            descriptions.add('Face ID');
            break;
          case BiometricType.fingerprint:
            descriptions.add('Fingerprint');
            break;
          case BiometricType.iris:
            descriptions.add('Iris');
            break;
          case BiometricType.strong:
            descriptions.add('Strong Biometric');
            break;
          case BiometricType.weak:
            descriptions.add('Weak Biometric');
            break;
        }
      }

      if (descriptions.length == 1) {
        return descriptions.first;
      } else if (descriptions.length == 2) {
        return '${descriptions[0]} or ${descriptions[1]}';
      } else {
        return '${descriptions.sublist(0, descriptions.length - 1).join(', ')}, or ${descriptions.last}';
      }
    } catch (e) {
      return 'Biometric authentication';
    }
  }

  /// Handle authentication errors and convert them to AuthResult
  AuthResult _handleAuthenticationError(dynamic error) {
    if (error is PlatformException) {
      switch (error.code) {
        case auth_error.notAvailable:
          return AuthResult.failure(
            'Biometric authentication is not available on this device',
            AuthResultType.notAvailable,
          );
        case auth_error.notEnrolled:
          return AuthResult.failure(
            'No biometric credentials are enrolled. Please set up fingerprint or face unlock in device settings',
            AuthResultType.notEnrolled,
          );
        case auth_error.lockedOut:
          return AuthResult.failure(
            'Too many failed attempts. Biometric authentication is temporarily locked. Try again later or use device password',
            AuthResultType.error,
          );
        case auth_error.permanentlyLockedOut:
          return AuthResult.failure(
            'Biometric authentication is permanently disabled. Please use device password or re-enable in settings',
            AuthResultType.error,
          );
        case auth_error.biometricOnlyNotSupported:
          return AuthResult.failure(
            'Device does not support biometric-only authentication. Fallback to device credentials is required',
            AuthResultType.error,
          );
        case 'UserCancel':
          return AuthResult.failure(
            'Authentication was cancelled by user',
            AuthResultType.cancelled,
          );
        case 'SystemCancel':
          return AuthResult.failure(
            'Authentication was cancelled by system',
            AuthResultType.cancelled,
          );
        case 'TouchIDNotAvailable':
          return AuthResult.failure(
            'Touch ID is not available on this device',
            AuthResultType.notAvailable,
          );
        case 'TouchIDNotEnrolled':
          return AuthResult.failure(
            'Touch ID is not set up. Please enroll fingerprints in device settings',
            AuthResultType.notEnrolled,
          );
        case 'FaceIDNotAvailable':
          return AuthResult.failure(
            'Face ID is not available on this device',
            AuthResultType.notAvailable,
          );
        case 'FaceIDNotEnrolled':
          return AuthResult.failure(
            'Face ID is not set up. Please enroll face recognition in device settings',
            AuthResultType.notEnrolled,
          );
        default:
          return AuthResult.failure(
            'Authentication error (${error.code}): ${error.message ?? 'Unknown error'}',
            AuthResultType.error,
          );
      }
    }

    return AuthResult.failure(
      'Unknown authentication error: $error',
      AuthResultType.error,
    );
  }

  /// Stop any ongoing authentication process
  Future<bool> stopAuthentication() async {
    try {
      return await _localAuth.stopAuthentication();
    } catch (e) {
      return false;
    }
  }

  /// Get biometric capability information for debugging
  Future<Map<String, dynamic>> getBiometricInfo() async {
    try {
      final isAvailable = await isBiometricAvailable();
      final isEnrolled = await isBiometricEnrolled();
      final availableBiometrics = await getAvailableBiometrics();
      final description = await getBiometricDescription();

      return {
        'isAvailable': isAvailable,
        'isEnrolled': isEnrolled,
        'availableBiometrics': availableBiometrics.map((e) => e.toString()).toList(),
        'description': description,
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}
