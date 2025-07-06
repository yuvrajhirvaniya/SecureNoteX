import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/biometric_service.dart';
import 'services/encryption_service.dart';
import 'services/secure_storage_service.dart';
import 'services/database_service.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  final secureStorage = SecureStorageService();
  final encryptionService = EncryptionService(secureStorage);
  final biometricService = BiometricService();
  final databaseService = DatabaseService(encryptionService);
  
  // Initialize encryption key
  await encryptionService.initialize();
  
  runApp(MyApp(
    secureStorage: secureStorage,
    encryptionService: encryptionService,
    biometricService: biometricService,
    databaseService: databaseService,
  ));
}

class MyApp extends StatelessWidget {
  final SecureStorageService secureStorage;
  final EncryptionService encryptionService;
  final BiometricService biometricService;
  final DatabaseService databaseService;

  const MyApp({
    Key? key,
    required this.secureStorage,
    required this.encryptionService,
    required this.biometricService,
    required this.databaseService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(biometricService),
        ),
        ChangeNotifierProvider(
          create: (_) => DataProvider(databaseService),
        ),
      ],
      child: MaterialApp(
        title: 'SecureNoteX - Digital Fortress',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            if (authProvider.isAuthenticated) {
              return const HomeScreen();
            } else {
              return const AuthScreen();
            }
          },
        ),
      ),
    );
  }
}
