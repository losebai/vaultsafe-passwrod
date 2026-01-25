/// Authentication type for sync endpoints
enum SyncAuthType {
  bearer,
  basic,
  custom,
}

extension SyncAuthTypeExtension on SyncAuthType {
  String get label {
    switch (this) {
      case SyncAuthType.bearer:
        return 'Bearer Token';
      case SyncAuthType.basic:
        return 'Basic Auth';
      case SyncAuthType.custom:
        return '自定义';
    }
  }
}
