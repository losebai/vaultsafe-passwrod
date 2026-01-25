# 🔒 VaultSafe — End-to-End Encrypted Password Manager

> **Secure · Private · Cross-Platform · End-to-End Encryption**

VaultSafe is an open-source, secure, cross-platform password manager built with Flutter. All sensitive data is encrypted locally on your device using your master key - **servers cannot decrypt any data**. Supports complete offline usage with optional encrypted cloud sync.

---

## ✨ Core Features

- 🔐 **End-to-End Encryption (E2EE)**: All data encrypted locally using PBKDF2-HMAC-SHA256 + AES-256-GCM
- 🌐 **Cross-Platform**: Single codebase for iOS, Android, Web, Windows, macOS, Linux
- 📦 **Password Management**:
  - Create, read, update, delete password entries
  - Copy usernames and passwords to clipboard
  - Secure password viewing with toggle visibility
  - Password generator utility (available for UI integration)
- 🗂️ **Group Management**: Organize passwords into groups/folders
- ⚙️ **Settings Center**:
  - Change master password (with password strength validation)
  - Enable/disable sync
  - Import/export encrypted backups (JSON format)
  - Auto-lock timeout configuration
  - Custom data directory selection
  - Biometric authentication toggle (UI ready, integration in progress)
- 🔄 **Third-Party Sync** (Foundation):
  - Configure custom sync endpoints
  - Multiple authentication methods (Bearer Token, Basic Auth, Custom Headers)
  - Manual sync trigger
  - Connection testing
- 🛡️ **Zero-Knowledge Architecture**: Server only stores encrypted blobs, cannot access plaintext
- 💾 **Data Persistence**: Hive-based encrypted local storage with automatic recovery on app restart

---

## 🛠 Tech Stack

- **Framework**: Flutter 3.24+ (Dart 3.5+)
- **State Management**: Riverpod + StateNotifier
- **Local Storage**:
  - **Hive** (v2.2.3) - Lightweight NoSQL database for encrypted data storage
  - **Hive Flutter** (v1.1.0) - Flutter integration for Hive
  - **flutter_secure_storage** (v9.2.2) - Secure storage for sensitive data (master key, tokens)
  - **shared_preferences** (v2.3.2) - Simple key-value pairs for app settings
  - **path_provider** (v2.1.3) - Cross-platform file system paths
- **Encryption**: `pointycastle` + `crypto` (PBKDF2 + AES-256-GCM)
- **Network**: `dio` + custom sync protocol
- **File Picker**: `file_picker` for backup import/export
- **Biometrics**: `local_auth` (Face ID / Touch ID / Windows Hello)
- **UI**: Material 3 Design System

---

## 📂 Project Structure

```
lib/
├── main.dart
├── core/
│   ├── encryption/       # Encryption core (key derivation, AES-GCM)
│   ├── sync/             # Sync engine with third-party API support
│   ├── backup/           # Backup/restore service
│   ├── storage/          # Hive-based encrypted local storage
│   └── security/         # Security policies
├── features/
│   ├── auth/             # Master password setup, authentication, unlock flow
│   ├── passwords/        # Password management UI & logic
│   ├── profile/          # Profile screen
│   ├── settings/         # Settings center (password, sync, backup)
│   └── home/             # Home screen with navigation
├── shared/
│   ├── models/           # Data models (PasswordEntry, PasswordGroup, Settings)
│   ├── providers/        # Riverpod providers (auth, passwords, settings)
│   ├── utils/            # Utilities (password generator, etc.)
│   └── platform/         # Platform-specific services
└── components/           # Reusable UI components
```

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.24 or higher
- Dart 3.5 or higher

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
# Android APK
flutter build apk --release

# Android App Bundle
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

---

## 🔑 Encryption Design

### Master Key Generation

1. User sets a **Master Password** (minimum 8 characters)
2. Key is derived using **PBKDF2-HMAC-SHA256** with 100,000 iterations
3. Results in a **32-byte (256-bit) Master Key**
4. Master key **never leaves the device**
5. Random salt generated and stored securely

### Data Encryption

- Each password entry encrypted with **AES-256-GCM** (authenticated encryption)
- Random **12-byte nonce** generated for each encryption
- Encrypted structure:
  ```json
  {
    "nonce": "base64...",
    "ciphertext": "base64...",
    "tag": "base64..."
  }
  ```
- All data Base64 encoded before storage

### Storage Architecture

#### Hive NoSQL Database

VaultSafe uses **Hive** as the primary local storage solution - a fast, lightweight key-value database optimized for Flutter.

**Data Organization (Boxes)**:
```
vault_safe_data/
├── passwords.hive        # Encrypted password entries
├── groups.hive           # Encrypted group/folder data
├── settings.hive         # Application settings
└── hive.lock             # File lock for concurrent access
```

**Key Features**:
- **Encrypted Boxes**: All data stored in Hive is pre-encrypted using AES-256-GCM
- **Three Storage Boxes**:
  - `passwords` - Stores all password entries (each encrypted individually)
  - `groups` - Stores folder/group organization
  - `settings` - Stores app configuration
- **Custom Directory Support**: Users can choose custom storage location
- **Write Permission Verification**: Automatic validation before initialization
- **Automatic Recovery**: Data persists across app restarts
- **Cross-Platform**: Works seamlessly on iOS, Android, Windows, macOS, Linux

**Default Storage Paths**:
- **Windows**: `%APPDATA%\vault_safe_data`
- **macOS**: `~/Library/Application Support/vault_safe_data`
- **Linux**: `~/.local/share/vault_safe_data`
- **Android**: `/data/data/<package>/app_flutter/vault_safe_data`
- **iOS**: `<App Home>/Documents/vault_safe_data`

#### Secure Storage Layer

Sensitive information is stored using platform-specific secure storage:

- **Android Keystore**: Hardware-backed key store for master key and sync tokens
- **iOS Keychain**: Encrypted storage for sensitive credentials
- **Windows/ Desktop**: Encrypted file-based storage

**What's Stored Securely**:
- Master password-derived encryption keys
- Third-party sync authentication tokens
- Device identifiers for sync
- Biometric authentication preferences

#### Simple Configuration Storage

- **SharedPreferences**: Lightweight key-value storage for:
  - UI preferences (theme, auto-lock timeout)
  - Feature flags (biometric enabled, sync enabled)
  - Last sync timestamp
  - User preferences

**Data Flow**:
1. User creates/edits password → Encrypts with AES-256-GCM → Stores in Hive `passwords` box
2. User changes settings → Updates Hive `settings` box (if sensitive) or SharedPreferences (if non-sensitive)
3. Sync token received → Encrypts with master key → Stores in flutter_secure_storage
4. App restart → Hive initializes all boxes → Data automatically available

---

## 🔄 Sync Configuration (Third-Party APIs)

VaultSafe supports syncing encrypted data to your own servers. All sync data is **AES-256-GCM encrypted** - third-party services cannot read the content.

### Supported Authentication Methods

| Method | Description |
|--------|-------------|
| **Bearer Token** | JWT or API token in Authorization header |
| **Basic Auth** | Username and password authentication |
| **Custom Headers** | Custom HTTP headers (e.g., `X-API-Key`) |

### Sync Protocol (REST API)

Your sync server needs to implement these two endpoints:

#### Upload Encrypted Data (POST)

```http
POST /api/v1/sync
Authorization: Bearer <token>
Content-Type: application/json

{
  "device_id": "uuid-string",
  "timestamp": 1705742400,
  "encrypted_data": "base64_encrypted_blob",
  "version": "1.0"
}
```

#### Download Encrypted Data (GET)

```http
GET /api/v1/sync
Authorization: Bearer <token>

Response:
{
  "device_id": "other-device-id",
  "timestamp": 1705742500,
  "encrypted_data": "base64_encrypted_blob",
  "version": "1.0"
}
```

> **Note**: The server only stores/returns the `encrypted_data` field. VaultSafe handles conflict resolution by keeping the latest timestamp.

---

## 📦 Backup & Restore

### Export Backup

1. Go to **Settings** > **Export Backup**
2. Backup will be encrypted using your master password
3. File saved to device's Downloads folder (or platform-specific location)
4. Filename format: `vaultsafe_backup_YYYY-MM-DDTHH-MM-SS.json`

### Import Backup

1. Go to **Settings** > **Import Backup**
2. Select your backup file (.json)
3. Preview backup information (version, encryption status, size, date)
4. Confirm import to restore data

> ⚠️ **Warning**: Importing a backup will overwrite existing data. Export current data first!

---

## 🏗️ Development Status

### ✅ Implemented Features

- [x] Master password setup and authentication
- [x] Password CRUD operations
- [x] Group/folder management
- [x] Encrypted local storage (Hive)
- [x] Import/export encrypted backups
- [x] Change master password
- [x] Auto-lock timeout settings
- [x] Third-party sync configuration
- [x] Password generator utility
- [x] Custom data directory selection
- [x] Detailed logging for debugging

### 🚧 In Progress

- [ ] Biometric authentication integration
- [ ] Auto-sync timer implementation
- [ ] Password strength indicator
- [ ] Password generator UI integration

### 📋 Planned Features

- [ ] Device list management
- [ ] Security event logging
- [ ] Theme switching (dark/light)
- [ ] Drag-and-drop group reordering
- [ ] Multi-level folder hierarchies
- [ ] Conflict detection and resolution
- [ ] Incremental sync
- [ ] Auto-fill integration (mobile)
- [ ] Anti-screenshot protection
- [ ] Unit tests (encryption, sync)
- [ ] Isar database migration (optional)

---

## 🔒 Security Architecture

### Zero-Knowledge Proof

- **Master Password**: Never stored or transmitted
- **Encryption Keys**: Derived locally, never leave device
- **Sync Credentials**: Encrypted with master key before storage
- **Server Data**: Only stores encrypted blobs (AES-256-GCM)

### Secure Storage

- **Android Keystore** / **iOS Keychain**: For sensitive data
- **Hive Encrypted Boxes**: For passwords and groups
- **Flutter Secure Storage**: For sync tokens and device ID

---

## 🐛 Troubleshooting

### Data Not Persisting After Restart

If you experience data loss after app restart:

1. **Check the logs** - Look for `StorageService:` debug messages showing:
   - Data directory path
   - Hive initialization status
   - Number of passwords/groups loaded

2. **Verify directory permissions** - The app needs write access to:
   - `getApplicationDocumentsDirectory()/vault_safe_data` (default)
   - Custom directory if configured

3. **Export backup regularly** - Use Settings > Export Backup to create encrypted backups

### Common Issues

- **"StorageService not initialized"**: Restart the app
- **"Directory not writable"**: Check app permissions or choose a different directory
- **Sync failing**: Use "Test Connection" button in sync settings

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🙌 Contributing

Contributions are welcome! Please ensure:

1. New features don't compromise encryption security
2. Code follows existing style and patterns
3. Sensitive data handling is properly documented
4. Tests are added for critical functionality (encryption, sync)

---

## 📞 Support

- **Issues**: Report bugs and feature requests on GitHub Issues
- **Documentation**: See `CLAUDE.md` for detailed Chinese documentation

---

> **VaultSafe — Your passwords belong only to you.**
> Started in 2026, built for privacy.
