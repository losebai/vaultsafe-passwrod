/// Auto-sync interval options
enum SyncInterval {
  none,
  every5Min,
  every15Min,
  hourly,
}

extension SyncIntervalExtension on SyncInterval {
  Duration get duration {
    switch (this) {
      case SyncInterval.none:
        return Duration.zero;
      case SyncInterval.every5Min:
        return const Duration(minutes: 5);
      case SyncInterval.every15Min:
        return const Duration(minutes: 15);
      case SyncInterval.hourly:
        return const Duration(hours: 1);
    }
  }
}
