# Secure Flutter App

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

## Dependencies

### Core Dependencies
- `flutter`: Flutter SDK
- `provider`: State management
- `sqflite`: SQLite database
- `encrypt`: AES encryption
- `flutter_secure_storage`: Secure key storage
- `local_auth`: Biometric authentication

### Supporting Dependencies
- `crypto`: Cryptographic functions
- `pointycastle`: Additional cryptographic algorithms
- `path`: File path utilities

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

## Usage

### First Launch
1. The app will generate and securely store encryption keys
2. Biometric authentication setup will be prompted
3. Sample data will be added in debug mode for demonstration

### Adding Secure Entries
1. Tap the "+" button on the home screen
2. Select entry type (Note, Password, Credit Card, Document, Other)
3. Enter title and content
4. Content is automatically encrypted before storage

### Viewing Entries
1. Browse entries by type using tabs
2. Search entries by title
3. Tap any entry to view details
4. Copy content to clipboard securely

### Authentication
- Biometric authentication required on app launch
- Session timeout configurable (default: 15 minutes)
- Automatic re-authentication for sensitive operations

## Security Considerations

### Data Protection
- All sensitive content encrypted with AES-256
- Encryption keys never stored in plain text
- Database schema designed to minimize data exposure

### Authentication Security
- Biometric data never leaves the device
- Fallback to device credentials when biometric unavailable
- Session management prevents unauthorized access

### Best Practices Implemented
- Secure random key generation
- Proper IV (Initialization Vector) usage
- PKCS7 padding for block cipher
- Secure storage using platform keychains
- Input validation and sanitization

## Testing

### Debug Features
- Simulate authentication for testing
- Sample data generation
- Detailed error logging
- Biometric capability information

### Manual Testing
1. Test biometric authentication flow
2. Verify data encryption/decryption
3. Test session timeout behavior
4. Validate CRUD operations
5. Test search functionality

## Troubleshooting

### Common Issues

#### Biometric Authentication Not Working
- Ensure device has biometric capabilities
- Check if biometric credentials are enrolled
- Verify app permissions

#### Encryption Errors
- Clear app data to regenerate keys
- Check secure storage permissions
- Verify encryption service initialization

#### Database Issues
- Clear app data to reset database
- Check file system permissions
- Verify SQLite compatibility

## Contributing

1. Follow Flutter best practices
2. Maintain security standards
3. Add tests for new features
4. Update documentation

## License

This project is for educational and demonstration purposes. Please review and adapt security measures for production use.

## Disclaimer

This application demonstrates secure data storage techniques. For production use, conduct thorough security audits and follow platform-specific security guidelines.
