import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:secure_note_x/main.dart';
import 'package:secure_note_x/services/biometric_service.dart';
import 'package:secure_note_x/services/encryption_service.dart';
import 'package:secure_note_x/services/secure_storage_service.dart';
import 'package:secure_note_x/services/database_service.dart';
import 'package:secure_note_x/providers/auth_provider.dart';
import 'package:secure_note_x/providers/data_provider.dart';

void main() {
  group('Secure Flutter App Tests', () {
    late SecureStorageService secureStorage;
    late EncryptionService encryptionService;
    late BiometricService biometricService;
    late DatabaseService databaseService;

    setUp(() async {
      // Initialize services for testing
      secureStorage = SecureStorageService();
      encryptionService = EncryptionService(secureStorage);
      biometricService = BiometricService();
      databaseService = DatabaseService(encryptionService);
      
      // Initialize encryption service
      await encryptionService.initialize();
    });

    testWidgets('App should build without errors', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(
        MyApp(
          secureStorage: secureStorage,
          encryptionService: encryptionService,
          biometricService: biometricService,
          databaseService: databaseService,
        ),
      );

      // Verify that the app builds successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Auth screen should be displayed when not authenticated', (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider(biometricService)),
            ChangeNotifierProvider(create: (_) => DataProvider(databaseService)),
          ],
          child: MaterialApp(
            home: Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                return authProvider.isAuthenticated 
                    ? const Scaffold(body: Text('Home'))
                    : const Scaffold(body: Text('Auth'));
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show auth screen when not authenticated
      expect(find.text('Auth'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    });

    test('Encryption service should encrypt and decrypt correctly', () async {
      const testData = 'This is sensitive test data';
      
      // Test encryption
      final encrypted = encryptionService.encrypt(testData);
      expect(encrypted, isNot(equals(testData)));
      expect(encrypted.length, greaterThan(0));

      // Test decryption
      final decrypted = encryptionService.decrypt(encrypted);
      expect(decrypted, equals(testData));
    });

    test('Encryption service should handle map data', () async {
      final testMap = {
        'username': 'testuser',
        'password': 'securepassword123',
        'notes': 'Important account information',
      };

      // Test map encryption
      final encrypted = encryptionService.encryptMap(testMap);
      expect(encrypted, isNot(equals(testMap.toString())));

      // Test map decryption
      final decrypted = encryptionService.decryptToMap(encrypted);
      expect(decrypted, equals(testMap));
    });

    test('Secure storage service should store and retrieve data', () async {
      const testKey = 'test_key';
      const testValue = 'test_value';

      // Test write
      await secureStorage.write(testKey, testValue);

      // Test read
      final retrievedValue = await secureStorage.read(testKey);
      expect(retrievedValue, equals(testValue));

      // Test contains key
      final containsKey = await secureStorage.containsKey(testKey);
      expect(containsKey, isTrue);

      // Test delete
      await secureStorage.delete(testKey);
      final deletedValue = await secureStorage.read(testKey);
      expect(deletedValue, isNull);
    });

    test('Biometric service should provide capability information', () async {
      // Test biometric availability check
      final isAvailable = await biometricService.isBiometricAvailable();
      expect(isAvailable, isA<bool>());

      // Test available biometrics
      final availableBiometrics = await biometricService.getAvailableBiometrics();
      expect(availableBiometrics, isA<List>());

      // Test biometric description
      final description = await biometricService.getBiometricDescription();
      expect(description, isA<String>());
      expect(description.isNotEmpty, isTrue);

      // Test biometric info
      final info = await biometricService.getBiometricInfo();
      expect(info, isA<Map<String, dynamic>>());
      expect(info.containsKey('isAvailable'), isTrue);
    });

    test('Auth provider should manage authentication state', () {
      final authProvider = AuthProvider(biometricService);

      // Initial state should be not authenticated
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, isNull);

      // Test authentication requirement
      expect(authProvider.isAuthenticationRequired(), isTrue);

      // Test debug simulation
      authProvider.simulateAuthentication();
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.lastAuthTime, isNotNull);

      // Test logout
      authProvider.logout();
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.lastAuthTime, isNull);
    });

    test('Data provider should manage entries', () {
      final dataProvider = DataProvider(databaseService);

      // Initial state
      expect(dataProvider.entries, isEmpty);
      expect(dataProvider.totalEntries, equals(0));
      expect(dataProvider.hasEntries, isFalse);

      // Test statistics
      final stats = dataProvider.getStatistics();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('total'), isTrue);
      expect(stats.containsKey('byType'), isTrue);
    });
  });

  group('Integration Tests', () {
    testWidgets('Complete app flow simulation', (WidgetTester tester) async {
      final secureStorage = SecureStorageService();
      final encryptionService = EncryptionService(secureStorage);
      final biometricService = BiometricService();
      final databaseService = DatabaseService(encryptionService);
      
      await encryptionService.initialize();

      await tester.pumpWidget(
        MyApp(
          secureStorage: secureStorage,
          encryptionService: encryptionService,
          biometricService: biometricService,
          databaseService: databaseService,
        ),
      );

      await tester.pumpAndSettle();

      // App should start with authentication screen
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // The app should be responsive and not crash
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });
}
