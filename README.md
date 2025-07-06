# SecureNoteX Flutter App

A comprehensive Flutter mobile application that securely stores sensitive user data using SQLite, AES 256-bit encryption, and biometric authentication.

## Features

- **🔐 AES 256-bit Encryption**: All data is encrypted using AES-256 in CBC mode with PKCS7 padding before storage
- **👆 Biometric Authentication**: Fingerprint and facial recognition support using local_auth
- **🗄️ Local SQLite Database**: Secure local storage using sqflite
- **🔑 Secure Key Management**: Encryption keys stored securely using flutter_secure_storage
- **📱 Cross-Platform**: Supports both Android and iOS
- **🎨 Modern UI**: Clean, intuitive interface with Material Design

## Security Architecture

### Encryption
- **Algorithm**: AES-256-CBC with PKCS7 padding
- **Key Generation**: Cryptographically secure random key generation
- **Key Storage**: Keys stored in device keychain/keystore using flutter_secure_storage
- **Data Flow**: All sensitive data is encrypted before SQLite storage and decrypted on retrieval

### Authentication
- **Primary**: Biometric authentication (fingerprint, face recognition)
- **Fallback**: Device credentials (PIN, pattern, password)
- **Session Management**: Configurable session timeout with automatic re-authentication

### Database
- **Local Storage**: SQLite database with encrypted content
- **Schema**: Structured tables with proper indexing for performance
- **CRUD Operations**: Full create, read, update, delete functionality

## Project Structure

```
lib/
├── main.dart                 # App entry point and initialization
├── models/                   # Data models
│   ├── secure_entry.dart     # Secure entry model with encryption support
│   └── auth_result.dart      # Authentication result model
├── services/                 # Core services
│   ├── encryption_service.dart      # AES encryption/decryption
│   ├── secure_storage_service.dart  # Secure key storage
│   ├── database_service.dart        # SQLite operations
│   └── biometric_service.dart       # Biometric authentication
├── providers/                # State management
│   ├── auth_provider.dart    # Authentication state
│   └── data_provider.dart    # Data management state
└── screens/                  # UI screens
    ├── auth_screen.dart      # Biometric authentication screen
    ├── home_screen.dart      # Main dashboard with encrypted data
    ├── add_entry_screen.dart # Form for adding/editing entries
    └── entry_detail_screen.dart # Detailed entry view
```

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode for platform-specific development
- Device with biometric capabilities for testing

### 2. Installation
```bash
# Clone the repository
git clone <repository-url>
cd secure_flutter_app

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 3. Platform Configuration

#### Android
Add the following permissions to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

#### iOS
Add the following to `ios/Runner/Info.plist`:
```xml
<key>NSFaceIDUsageDescription</key>
<string>This app uses Face ID for secure authentication</string>
```
