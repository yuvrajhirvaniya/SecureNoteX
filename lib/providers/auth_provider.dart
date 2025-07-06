import 'package:flutter/foundation.dart';
import '../services/biometric_service.dart';
import '../models/auth_result.dart';

/// Provider for managing authentication state throughout the app
/// Handles biometric authentication, session management, and auth state persistence
class AuthProvider extends ChangeNotifier {
  final BiometricService _biometricService;
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastAuthTime;
  bool _biometricAvailable = false;
  bool _biometricEnrolled = false;
  String _biometricDescription = '';

  AuthProvider(this._biometricService) {
    _initializeBiometricInfo();
  }

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastAuthTime => _lastAuthTime;
  bool get biometricAvailable => _biometricAvailable;
  bool get biometricEnrolled => _biometricEnrolled;
  String get biometricDescription => _biometricDescription;
  BiometricService get biometricService => _biometricService;

  /// Initialize biometric information on provider creation
  Future<void> _initializeBiometricInfo() async {
    try {
      _biometricAvailable = await _biometricService.isBiometricAvailable();
      _biometricEnrolled = await _biometricService.isBiometricEnrolled();
      _biometricDescription = await _biometricService.getBiometricDescription();
      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize biometric info: $e');
    }
  }

  /// Authenticate user using biometric authentication
  Future<bool> authenticateWithBiometrics({
    String? customReason,
    bool useErrorDialogs = true,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final reason = customReason ??
          'Please authenticate with $_biometricDescription to access your secure data';

      // First try with weak biometrics allowed for better compatibility
      AuthResult result = await _biometricService.authenticateWithWeakBiometrics(
        localizedReason: reason,
        useErrorDialogs: useErrorDialogs,
      );

      // If weak biometrics fail, try regular biometric authentication
      if (!result.isSuccess) {
        result = await _biometricService.authenticateWithBiometrics(
          localizedReason: reason,
          useErrorDialogs: useErrorDialogs,
        );
      }

      if (result.isSuccess) {
        _setAuthenticated(true);
        _lastAuthTime = DateTime.now();
        return true;
      } else {
        _setError(result.errorMessage ?? 'Authentication failed');
        return false;
      }
    } catch (e) {
      _setError('Authentication error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Authenticate using only biometric methods (no device credentials fallback)
  Future<bool> authenticateWithBiometricsOnly({
    String? customReason,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final reason = customReason ?? 
          'Please authenticate with $_biometricDescription';

      final AuthResult result = await _biometricService.authenticateWithBiometricsOnly(
        localizedReason: reason,
      );

      if (result.isSuccess) {
        _setAuthenticated(true);
        _lastAuthTime = DateTime.now();
        return true;
      } else {
        _setError(result.errorMessage ?? 'Biometric authentication failed');
        return false;
      }
    } catch (e) {
      _setError('Biometric authentication error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if authentication is required based on session timeout
  bool isAuthenticationRequired({Duration sessionTimeout = const Duration(minutes: 15)}) {
    if (!_isAuthenticated) return true;
    
    if (_lastAuthTime == null) return true;
    
    final timeSinceAuth = DateTime.now().difference(_lastAuthTime!);
    return timeSinceAuth > sessionTimeout;
  }

  /// Refresh authentication if session has expired
  Future<bool> refreshAuthenticationIfNeeded({
    Duration sessionTimeout = const Duration(minutes: 15),
    String? customReason,
  }) async {
    if (!isAuthenticationRequired(sessionTimeout: sessionTimeout)) {
      return true; // Already authenticated and session is valid
    }

    return await authenticateWithBiometrics(customReason: customReason);
  }

  /// Logout user and clear authentication state
  Future<void> logout() async {
    _setAuthenticated(false);
    _lastAuthTime = null;
    _clearError();
    
    // Stop any ongoing authentication
    await _biometricService.stopAuthentication();
  }

  /// Refresh biometric availability (useful after settings changes)
  Future<void> refreshBiometricInfo() async {
    try {
      _biometricAvailable = await _biometricService.isBiometricAvailable();
      _biometricEnrolled = await _biometricService.isBiometricEnrolled();
      _biometricDescription = await _biometricService.getBiometricDescription();
      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh biometric info: $e');
    }
  }

  /// Get detailed biometric information for debugging
  Future<Map<String, dynamic>> getBiometricInfo() async {
    return await _biometricService.getBiometricInfo();
  }

  /// Check if user can authenticate (biometric is available and enrolled)
  bool canAuthenticate() {
    return _biometricAvailable && _biometricEnrolled;
  }

  /// Get authentication status message for UI
  String getAuthStatusMessage() {
    if (!_biometricAvailable) {
      return 'Biometric authentication is not available on this device';
    }
    
    if (!_biometricEnrolled) {
      return 'No biometric credentials are enrolled. Please set up $_biometricDescription in device settings';
    }
    
    if (_isAuthenticated) {
      return 'Authenticated with $_biometricDescription';
    }
    
    return 'Please authenticate with $_biometricDescription';
  }

  /// Private helper methods
  void _setAuthenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Simulate authentication for testing purposes (only in debug mode)
  void simulateAuthentication() {
    if (kDebugMode) {
      _setAuthenticated(true);
      _lastAuthTime = DateTime.now();
    }
  }

  /// Force logout for testing purposes (only in debug mode)
  void forceLogout() {
    if (kDebugMode) {
      logout();
    }
  }
}
