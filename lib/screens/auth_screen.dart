import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';

/// Authentication screen with biometric prompt and fallback options
/// This is the entry point for user authentication
class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkBiometricAvailability();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _checkBiometricAvailability() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.refreshBiometricInfo();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: _buildAuthContent(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAuthContent() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                         MediaQuery.of(context).padding.top -
                         MediaQuery.of(context).padding.bottom - 40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAppLogo(),
                const SizedBox(height: 24),
                _buildWelcomeText(),
                const SizedBox(height: 20),
                _buildAuthStatusCard(authProvider),
                const SizedBox(height: 20),
                _buildAuthButton(authProvider),
                if (authProvider.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(authProvider.errorMessage!),
                ],
                const SizedBox(height: 20),
                _buildDebugSection(authProvider),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppLogo() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.goldGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'VaultGuardian',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your Digital Fortress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Please authenticate to access your secure data',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAuthStatusCard(AuthProvider authProvider) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _getStatusColor(authProvider).withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: _getStatusColor(authProvider).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Icon(
              _getStatusIcon(authProvider),
              size: 40,
              color: _getStatusColor(authProvider),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            authProvider.getAuthStatusMessage(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (authProvider.biometricAvailable && authProvider.biometricEnrolled) ...[
            const SizedBox(height: 12),
            Text(
              'Secure access with ${authProvider.biometricDescription}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthButton(AuthProvider authProvider) {
    if (!authProvider.canAuthenticate()) {
      return _buildSettingsButton();
    }

    return GradientButton(
      text: authProvider.isLoading
          ? 'Authenticating...'
          : 'Unlock Vault',
      icon: authProvider.isLoading ? null : _getBiometricIcon(authProvider),
      isLoading: authProvider.isLoading,
      onPressed: authProvider.isLoading ? null : () => _authenticate(authProvider),
      width: double.infinity,
      height: 60,
    );
  }

  Widget _buildSettingsButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSettingsDialog(),
          borderRadius: BorderRadius.circular(12),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'Setup Biometric Authentication',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection(AuthProvider authProvider) {
    // Only show in debug mode
    if (!const bool.fromEnvironment('dart.vm.product')) {
      return Column(
        children: [
          const Divider(color: Colors.white54),
          const SizedBox(height: 16),
          Text(
            'Debug Options',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => authProvider.simulateAuthentication(),
            child: const Text(
              'Simulate Authentication',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => _showBiometricInfo(authProvider),
            child: const Text(
              'Show Biometric Info',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () => _testWeakBiometric(authProvider),
            child: const Text(
              'Test Weak Biometric',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
  

  // Helper methods
  IconData _getStatusIcon(AuthProvider authProvider) {
    if (!authProvider.biometricAvailable) return Icons.error_outline;
    if (!authProvider.biometricEnrolled) return Icons.warning_amber;
    return Icons.fingerprint;
  }

  Color _getStatusColor(AuthProvider authProvider) {
    if (!authProvider.biometricAvailable) return Colors.red;
    if (!authProvider.biometricEnrolled) return Colors.orange;
    return Colors.green;
  }

  IconData _getBiometricIcon(AuthProvider authProvider) {
    if (authProvider.biometricDescription.toLowerCase().contains('face')) {
      return Icons.face;
    }
    return Icons.fingerprint;
  }

  Future<void> _authenticate(AuthProvider authProvider) async {
    final success = await authProvider.authenticateWithBiometrics();
    
    if (!success && mounted) {
      // Show additional help if authentication failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Authentication failed'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _authenticate(authProvider),
          ),
        ),
      );
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biometric Setup Required'),
        content: const Text(
          'To use this app, you need to set up biometric authentication (fingerprint or face recognition) in your device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Debug methods
  Future<void> _showBiometricInfo(AuthProvider authProvider) async {
    final info = await authProvider.getBiometricInfo();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Biometric Information'),
          content: SingleChildScrollView(
            child: Text(info.toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _testWeakBiometric(AuthProvider authProvider) async {
    try {
      final biometricService = authProvider.biometricService;
      final result = await biometricService.authenticateWithWeakBiometrics(
        localizedReason: 'Testing weak biometric authentication',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isSuccess
                  ? 'Weak biometric test successful!'
                  : 'Weak biometric test failed: ${result.errorMessage}',
            ),
            backgroundColor: result.isSuccess ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing weak biometric: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
