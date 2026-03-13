// infrastructure/utils/dio.key.dart
class BGService {
  static const String tracksolidApiKey =
      '3667aa890aeff9cb0825fa6f70ee623db6bc4fc80d74a2a30b134a5a8ae78ecd';
  // BLE Service Configuration
  static const String bgChannelId = 'bearcon_bg_channel_v3';
  static const String bgChannelName = 'Bearcon Background Service';
  static const int foregroundNotificationId = 888;
  // Timing (Seconds)
  static const int scanDuration = 15;
  static const int cooldownMinutes = 1;

  // ── Adaptive Scan Service Configuration Constants ───────────────────────────────────────────────

  /// Thresholds
  static const double speedThresholdHot = 20.0; // km/h
  static const double accelThresholdWarmMin = 0.3;
  static const double accelThresholdCold = 0.2;

  /// Durations
  static const Duration coldBufferDuration = Duration(minutes: 5);
  static const Duration warmUpgradeDuration = Duration(seconds: 3);
  static const Duration hotCooldownDuration = Duration(minutes: 1);

  /// Scan cycle intervals & lengths
  static const Duration hotScanInterval = Duration(minutes: 1);
  static const Duration hotScanDuration = Duration(seconds: 15);

  static const Duration warmScanInterval = Duration(minutes: 3);
  static const Duration warmScanDuration = Duration(seconds: 30);

  static const Duration coldScanInterval = Duration(minutes: 10);
  static const Duration coldScanDuration = Duration(seconds: 30);
}
