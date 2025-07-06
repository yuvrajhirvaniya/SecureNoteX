/// Result model for authentication operations
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final AuthResultType type;

  AuthResult({
    required this.isSuccess,
    this.errorMessage,
    required this.type,
  });

  /// Factory constructor for successful authentication
  factory AuthResult.success(AuthResultType type) {
    return AuthResult(
      isSuccess: true,
      type: type,
    );
  }

  /// Factory constructor for failed authentication
  factory AuthResult.failure(String errorMessage, AuthResultType type) {
    return AuthResult(
      isSuccess: false,
      errorMessage: errorMessage,
      type: type,
    );
  }

  @override
  String toString() {
    return 'AuthResult{isSuccess: $isSuccess, errorMessage: $errorMessage, type: $type}';
  }
}

/// Enum for different types of authentication results
enum AuthResultType {
  biometric,
  fallback,
  cancelled,
  error,
  notAvailable,
  notEnrolled,
}

/// Extension to get display messages for AuthResultType
extension AuthResultTypeExtension on AuthResultType {
  String get displayMessage {
    switch (this) {
      case AuthResultType.biometric:
        return 'Biometric authentication successful';
      case AuthResultType.fallback:
        return 'Fallback authentication successful';
      case AuthResultType.cancelled:
        return 'Authentication cancelled by user';
      case AuthResultType.error:
        return 'Authentication error occurred';
      case AuthResultType.notAvailable:
        return 'Biometric authentication not available';
      case AuthResultType.notEnrolled:
        return 'No biometric credentials enrolled';
    }
  }
}
