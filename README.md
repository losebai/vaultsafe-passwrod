# VaultSafe - End-to-End Encrypted Password Manager

> **Secure · Private · Cross-Platform · End-to-End Encryption**

VaultSafe is an open-source, secure, cross-platform password manager built with Flutter. All sensitive data is encrypted locally on your device using your master key - **servers cannot decrypt any data**.

## Core Features

- 🔐 **End-to-End Encryption (E2EE)**: All data encrypted locally using PBKDF2 + AES-256-GCM
- 🌐 **Cross-Platform**: Single codebase for iOS, Android, Web, Windows, macOS, Linux
- 📦 **Password Management**: Create, read, update, delete password entries
- 🗂️ **Group Management**: Organize passwords into groups/folders
- 👤 **Profile**: View account info and device list
- ⚙️ **Settings**:
  - Change master password
  - Enable/disable sync
  - Import/export encrypted backups
  - Biometric authentication (Face ID / Touch ID / Windows Hello)
  - Auto-lock timeout
- 🔄 **Third-Party Sync**: Use your own sync server (WebDAV, custom REST API, etc.)
- 🛡️ **Zero-Knowledge Architecture**: Server only stores encrypted blobs

## Tech Stack

- **Framework**: Flutter 3.24+ (Dart 3.5+)
- **State Management**: Riverpod + AsyncNotifier
- **Local Storage**: Hive (encrypted) + Isar (NoSQL)
- **Encryption**: `pointycastle` + `crypto`
- **Network**: `dio` + custom sync protocol
- **UI**: Material 3

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── encryption/       # Encryption core (key derivation, AES-GCM)
│   ├── sync/             # Sync engine with third-party API support
│   └── security/         # Security policies (anti-screenshot, auto-lock)
├── features/
│   ├── auth/             # Master password authentication, unlock flow
│   ├── passwords/        # Password management UI & logic
│   ├── groups/           # Group management
│   ├── profile/          # Profile screen
│   ├── settings/         # Settings center
│   └── home/             # Home screen with navigation
└── shared/
    ├── models/           # Data models
    ├── providers/        # Riverpod providers
    └── utils/            # Utilities (password generator, etc.)
```

## Getting Started

### Install Dependencies

```bash
flutter pub get
```

### Run on Different Platforms

```bash
# Mobile
flutter run -d android
flutter run -d ios

# Web
flutter run -d chrome --web-renderer html

# Desktop
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

### Build for Release

```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ipa --release

# Web
flutter build web

# Desktop
flutter build windows
flutter build macos
flutter build linux
```

## Encryption Design

### Master Key Generation
1. User sets a **Master Password**
2. Key is derived using **PBKDF2-HMAC-SHA256** (100,000 iterations)
3. Results in a **32-byte Master Key**
4. Master key never leaves the device

### Data Encryption
- Each password entry encrypted with **AES-256-GCM**
- Random nonce generated for each encryption
- Encrypted data Base64 encoded and stored locally

### Sync Architecture
- All data encrypted before upload
- Supports custom third-party endpoints
- Authentication methods: Bearer Token, Basic Auth, Custom Headers
- Conflict resolution: Keep latest by timestamp

## Third-Party Sync Protocol

### Upload (POST)

```http
POST /api/v1/sync
Authorization: Bearer <token>
Content-Type: application/json

{
  "device_id": "uuid",
  "timestamp": 1705742400,
  "encrypted_data": "base64(...)",
  "version": "1.0"
}
```

### Download (GET)

```http
GET /api/v1/sync
Authorization: Bearer <token>
```

## License

MIT License - See LICENSE file for details

## Contributing

1. Ensure new features don't compromise encryption security
2. Write unit tests for encryption and sync logic
3. Follow code style guidelines
