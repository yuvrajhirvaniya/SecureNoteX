/// Example usage of the Secure Flutter App services
/// This file demonstrates how to use the core services independently

import 'package:vault_guardian/services/encryption_service.dart';
import 'package:vault_guardian/services/secure_storage_service.dart';
import 'package:vault_guardian/services/database_service.dart';
import 'package:vault_guardian/services/biometric_service.dart';
import 'package:vault_guardian/models/secure_entry.dart';

/// Example of using the encryption service
Future<void> encryptionExample() async {
  print('=== Encryption Service Example ===');
  
  // Initialize services
  final secureStorage = SecureStorageService();
  final encryptionService = EncryptionService(secureStorage);
  
  // Initialize encryption (generates keys if needed)
  await encryptionService.initialize();
  
  // Example 1: Encrypt and decrypt a simple string
  const sensitiveData = 'This is my secret password: MySecurePass123!';
  print('Original data: $sensitiveData');
  
  final encrypted = encryptionService.encrypt(sensitiveData);
  print('Encrypted data: $encrypted');
  
  final decrypted = encryptionService.decrypt(encrypted);
  print('Decrypted data: $decrypted');
  print('Match: ${sensitiveData == decrypted}');
  
  // Example 2: Encrypt and decrypt a Map (JSON-like data)
  final userData = {
    'username': 'john_doe',
    'email': 'john@example.com',
    'password': 'SuperSecretPassword123!',
    'notes': 'Important account for work',
    'created': DateTime.now().toIso8601String(),
  };
  
  print('\nOriginal map: $userData');
  
  final encryptedMap = encryptionService.encryptMap(userData);
  print('Encrypted map: $encryptedMap');
  
  final decryptedMap = encryptionService.decryptToMap(encryptedMap);
  print('Decrypted map: $decryptedMap');
  print('Maps match: ${userData.toString() == decryptedMap.toString()}');
  
  // Example 3: Generate hash for data integrity
  final hash = encryptionService.generateHash(sensitiveData);
  print('\nSHA-256 hash: $hash');
}

/// Example of using the secure storage service
Future<void> secureStorageExample() async {
  print('\n=== Secure Storage Service Example ===');
  
  final secureStorage = SecureStorageService();
  
  // Example 1: Basic key-value storage
  await secureStorage.write('user_preference', 'dark_mode');
  final preference = await secureStorage.read('user_preference');
  print('Stored preference: $preference');
  
  // Example 2: Authentication state management
  await secureStorage.saveAuthState(true);
  final isAuthenticated = await secureStorage.getAuthState();
  print('Authentication state: $isAuthenticated');
  
  // Example 3: Biometric preferences
  await secureStorage.setBiometricEnabled(true);
  final biometricEnabled = await secureStorage.isBiometricEnabled();
  print('Biometric enabled: $biometricEnabled');
  
  // Example 4: Check if first launch
  final isFirstLaunch = await secureStorage.isFirstLaunch();
  print('Is first launch: $isFirstLaunch');
  
  // Example 5: Get all stored data (for debugging)
  final allData = await secureStorage.readAll();
  print('All stored data keys: ${allData.keys.toList()}');
}

/// Example of using the database service
Future<void> databaseExample() async {
  print('\n=== Database Service Example ===');
  
  // Initialize services
  final secureStorage = SecureStorageService();
  final encryptionService = EncryptionService(secureStorage);
  await encryptionService.initialize();
  
  final databaseService = DatabaseService(encryptionService);
  
  // Example 1: Create and insert secure entries
  final entries = [
    SecureEntry(
      title: 'Email Account',
      content: 'Password: MyEmailPass123!\nRecovery: backup@email.com',
      type: SecureEntryType.loginCredentials,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SecureEntry(
      title: 'Important Note',
      content: 'Remember to backup data every Friday at 5 PM',
      type: SecureEntryType.personalNote,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    SecureEntry(
      title: 'Credit Card',
      content: 'Card: 1234 5678 9012 3456\nExpiry: 12/25\nCVV: 123',
      type: SecureEntryType.paymentCard,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
  
  // Insert entries
  for (final entry in entries) {
    final id = await databaseService.insertSecureEntry(entry);
    print('Inserted entry "${entry.title}" with ID: $id');
  }
  
  // Example 2: Retrieve all entries
  final allEntries = await databaseService.getAllSecureEntries();
  print('\nRetrieved ${allEntries.length} entries:');
  for (final entry in allEntries) {
    print('- ${entry.title} (${entry.type.displayName})');
  }
  
  // Example 3: Search entries
  final searchResults = await databaseService.searchSecureEntries('email');
  print('\nSearch results for "email": ${searchResults.length} found');
  
  // Example 4: Get entries by type
  final passwordEntries = await databaseService.getSecureEntriesByType(SecureEntryType.loginCredentials);
  print('Password entries: ${passwordEntries.length}');
  
  // Example 5: Get statistics
  final stats = await databaseService.getEntriesCountByType();
  print('\nEntry statistics:');
  stats.forEach((type, count) {
    print('- ${type.displayName}: $count');
  });
}

/// Example of using the biometric service
Future<void> biometricExample() async {
  print('\n=== Biometric Service Example ===');
  
  final biometricService = BiometricService();
  
  // Example 1: Check biometric availability
  final isAvailable = await biometricService.isBiometricAvailable();
  print('Biometric available: $isAvailable');
  
  final isEnrolled = await biometricService.isBiometricEnrolled();
  print('Biometric enrolled: $isEnrolled');
  
  // Example 2: Get available biometric types
  final availableBiometrics = await biometricService.getAvailableBiometrics();
  print('Available biometrics: $availableBiometrics');
  
  // Example 3: Get user-friendly description
  final description = await biometricService.getBiometricDescription();
  print('Biometric description: $description');
  
  // Example 4: Get detailed biometric info
  final info = await biometricService.getBiometricInfo();
  print('Biometric info: $info');
  
  // Example 5: Attempt authentication (commented out for example)
  /*
  if (isAvailable && isEnrolled) {
    final authResult = await biometricService.authenticateWithBiometrics(
      localizedReason: 'Please authenticate to access example data',
    );
    print('Authentication result: ${authResult.isSuccess}');
    if (!authResult.isSuccess) {
      print('Error: ${authResult.errorMessage}');
    }
  }
  */
}

/// Example of creating and managing secure entries
void secureEntryExample() {
  print('\n=== Secure Entry Model Example ===');
  
  // Example 1: Create different types of entries
  final passwordEntry = SecureEntry(
    title: 'GitHub Account',
    content: 'username: myuser\npassword: SecurePass123!\ntoken: ghp_xxxxxxxxxxxx',
    type: SecureEntryType.loginCredentials,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  final noteEntry = SecureEntry(
    title: 'Meeting Notes',
    content: 'Project deadline: March 15th\nTeam meeting: Every Monday 10 AM\nImportant: Review security protocols',
    type: SecureEntryType.personalNote,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  final cardEntry = SecureEntry(
    title: 'Business Credit Card',
    content: 'Card Number: 4532 1234 5678 9012\nExpiry: 08/26\nCVV: 456\nBank: Example Bank',
    type: SecureEntryType.paymentCard,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  
  final entries = [passwordEntry, noteEntry, cardEntry];
  
  // Example 2: Display entry information
  for (final entry in entries) {
    print('\nEntry: ${entry.title}');
    print('Type: ${entry.type.displayName} ${entry.type.icon}');
    print('Created: ${entry.createdAt}');
    print('Content length: ${entry.content.length} characters');
  }
  
  // Example 3: Convert to/from Map (for database storage)
  final entryMap = passwordEntry.toMap();
  print('\nEntry as Map: $entryMap');
  
  final recreatedEntry = SecureEntry.fromMap(entryMap);
  print('Recreated entry title: ${recreatedEntry.title}');
  print('Entries match: ${passwordEntry.title == recreatedEntry.title}');
  
  // Example 4: Create updated copy
  final updatedEntry = passwordEntry.copyWith(
    content: 'Updated password: NewSecurePass456!',
    updatedAt: DateTime.now(),
  );
  print('\nOriginal content length: ${passwordEntry.content.length}');
  print('Updated content length: ${updatedEntry.content.length}');
}

/// Main example function that runs all examples
Future<void> main() async {
  print('Secure Flutter App - Service Examples');
  print('=====================================');
  
  try {
    // Run all examples
    await encryptionExample();
    await secureStorageExample();
    await databaseExample();
    await biometricExample();
    secureEntryExample();
    
    print('\n=== All Examples Completed Successfully ===');
  } catch (e) {
    print('\nError running examples: $e');
  }
}

/// Additional utility functions for testing

/// Generate sample secure entries for testing
List<SecureEntry> generateSampleEntries() {
  return [
    SecureEntry(
      title: 'Work Email',
      content: 'email: work@company.com\npassword: WorkPass123!',
      type: SecureEntryType.loginCredentials,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SecureEntry(
      title: 'Project Ideas',
      content: '1. Mobile security app\n2. Encrypted note-taking\n3. Secure file sharing',
      type: SecureEntryType.personalNote,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now(),
    ),
    SecureEntry(
      title: 'Personal Credit Card',
      content: 'Card: 5555 4444 3333 2222\nExpiry: 12/27\nCVV: 789',
      type: SecureEntryType.paymentCard,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    SecureEntry(
      title: 'Important Document',
      content: 'Passport Number: AB1234567\nIssue Date: 01/01/2020\nExpiry: 01/01/2030',
      type: SecureEntryType.identityDocument,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];
}
