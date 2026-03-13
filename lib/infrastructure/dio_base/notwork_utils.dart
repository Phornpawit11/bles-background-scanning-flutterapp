import 'dart:math';

class NetworkUtils {
  /// สร้างเวลารอแบบ Exponential Backoff + Jitter
  static List<Duration> generateSmartRetryDelays(int retries) {
    final random = Random();
    final int baseDelayMs = 1000; // เริ่มต้นที่ 1 วินาที

    return List.generate(retries, (index) {
      // 1. Exponential: รอบที่ 0=1s, รอบที่ 1=2s, รอบที่ 2=4s, รอบที่ 3=8s
      int exponentialDelay = baseDelayMs * pow(2, index).toInt();

      // 2. Jitter: สุ่มบวกเวลาเพิ่มไปอีก 0 - 500 มิลลิวินาที
      int jitter = random.nextInt(500);

      return Duration(milliseconds: exponentialDelay + jitter);
    });
  }
}
