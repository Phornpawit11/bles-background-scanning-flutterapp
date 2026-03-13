import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:bearcon_card_app/utils/bgservice.key.dart';

/// ระดับความเข้มข้นของการสแกน (Adaptive Modes)
/// - `HOT` = ขับรถ (เร็ว/ยิงถี่)
/// - `WARM` = เดิน (ปานกลาง)
/// - `COLD` = โหมดจำศีล (อยู่นิ่งๆ/ยิงห่างๆ)
enum AdaptiveScanMode { HOT, WARM, COLD }

/// คลาส [AdaptiveScanService] บริการอัจฉริยะที่ใช้ประหยัดแบตเตอรี่ด้วยเซนเซอร์
/// 
/// **หน้าที่หลัก (Responsibilities):**
/// ควบคุมและเปลี่ยนความถี่ (Frequency) ในการสแกนหา BLE Beacon คอยอ่านค่าจาก Accelerometer ของเครื่อง 
/// ว่าผู้ใช้กำลังนั่งนิ่งๆ, เดิน, หรือ ขับรถ จากนั้นจะกะจังหวะ (Throttle) ส่งคำสั่งไปสั่งเปิดสแกน
/// 
/// **Business Logic (The "Why"):**
/// การเปิดสแกนแบบ High Power/Low Latency ตลอดเวลาจะทำให้แบตสมาร์ทโฟนหมดภายในไม่กี่ชั่วโมง
/// เซอร์วิสนี้จึงเป็น "สมองกล" คอยจับ Accelerometer ตลอด (เพราะกินไฟน้อยมาก)
/// หากเห็นว่าเดินอยู่ ก็จะลองยิง GPS (GPS กินไฟกลางๆ) ว่าเร็วเกิน 20 กม/ชม ไหม
/// ถ้าใช่จะเข้าระบบ HOT ทำให้ลดการกินแบตเตอรี่ได้มหาศาลหากไม่ได้ขับรถ
class AdaptiveScanService {
  AdaptiveScanMode _currentMode = AdaptiveScanMode.COLD;
  AdaptiveScanMode get currentMode => _currentMode;

  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  Timer? _coldTimer;
  Timer? _hotCooldownTimer;
  Timer? _scanCycleTimer;
  Timer? _warmUpgradeTimer;

  // ── Debouncing & Throttling ───────────────────────────────────────────────

  // Moving average for accelerometer to prevent flickering
  final List<double> _accelBuffer = [];
  static const int _accelBufferSize = 5;

  DateTime _lastSpeedCheckTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _speedCheckThrottleLimit = Duration(seconds: 30);

  // ── Callbacks ─────────────────────────────────────────────────────────────

  /// ฟังก์ชัน Callback สำหรับจุดชนวนบอกเพื่อนบ้าน (BackgroundBleController) ให้ทำการสแกน BLE จริงๆ
  /// โดยจะรอ [scanDuration] เป็นระยะเวลาที่กำหนดให้เปิดกล้องสแกน
  final Future<void> Function(Duration scanDuration) onTriggerScan;

  /// ฟังก์ชัน Callback สำหรับบอกเพื่อนบ้านให้ "บังคับปิดกล้องสแกน" 
  /// เกิดขึ้นบ่อยๆ เวลามีการสลับโหมดกะทันหัน (เช่น เดินอยู่ดีๆ แล้วขึ้นรถ)
  final VoidCallback onStopScan;

  /// Emits whenever the internal AdaptiveScanMode changes.
  final void Function(AdaptiveScanMode mode)? onModeChanged;

  bool _isRunning = false;
  bool _isCheckingSpeed = false;
  int _lowSpeedCount = 0;

  AdaptiveScanService({
    required this.onTriggerScan,
    required this.onStopScan,
    this.onModeChanged,
  });

  /// Starts the adaptive scanning logic
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _accelBuffer.clear();
    _startAccelerometerListener();

    // 🚨 ลบบรรทัด _setMode(AdaptiveScanMode.COLD); ทิ้งไป

    // ✅ เพิ่ม 2 บรรทัดนี้แทน เพื่อบังคับเริ่มทำงานและอัปเดต UI ทันที
    onModeChanged?.call(_currentMode);
    _startScanCycle();
  }

  /// ปิดการทำงานของ Listener และ Timer ทั้งหมดของระบบ (Clean Up)
  void stop() {
    _isRunning = false;
    _accelSub?.cancel();
    _coldTimer?.cancel();
    _hotCooldownTimer?.cancel();
    _scanCycleTimer?.cancel();
    _warmUpgradeTimer?.cancel();
    onStopScan();
  }

  // ── Sensor Logic ──────────────────────────────────────────────────────────

  void _startAccelerometerListener() {
    // userAccelerometerEventStream removes gravity automatically
    _accelSub = userAccelerometerEventStream(
            samplingPeriod: SensorInterval.normalInterval)
        .listen((event) {
      if (!_isRunning) return;

      double magnitude =
          sqrt((event.x * event.x) + (event.y * event.y) + (event.z * event.z));

      // iOS userAccelerometer reports in Gs (1G = 9.81 m/s^2)
      // Android reports in m/s^2. We normalize iOS to m/s^2 so thresholds match.

      // Keep a moving average buffer
      _accelBuffer.add(magnitude);
      if (_accelBuffer.length > _accelBufferSize) {
        _accelBuffer.removeAt(0);
      }

      // Need a full buffer to make an accurate decision
      if (_accelBuffer.length < _accelBufferSize) return;

      final double avgMagnitude =
          _accelBuffer.reduce((a, b) => a + b) / _accelBuffer.length;

      if (avgMagnitude < BGService.accelThresholdCold) {
        _handleStillState();
      } else if (avgMagnitude >= BGService.accelThresholdWarmMin) {
        _handleMotionState(avgMagnitude);
      } else {
        // กรณีอยู่ตรงกลาง (0.2 ถึง 0.3) ถือว่ามีการขยับเบาๆ
        // ให้ยกเลิกการนับถอยหลังเข้าโหมด COLD เพื่อป้องกันแอปหลับ
        _coldTimer?.cancel();
      }
    });
  }

  /// จัดการสถานะ "อยู่นิ่ง" (Resting/Still)
  /// 
  /// **Business Logic (The "Why"):**
  /// หากก่อนหน้านี้เป็นโหมด WARM แล้วผู้ใช้อยู่นิ่งๆ ระบบจะไม่ลดระดับเป็น COLD ทันที 
  /// เพราะผู้ใช้อาจจะแค่หยุดยืนซื้อของ (Debounce) ระบบจะนับถอยหลังอีก 5 นาที (`coldBufferDuration`)
  /// หากผ่านไป 5 นาทีไม่ได้ขยับเลย ถึงจะปรับลดให้เป็น COLD
  void _handleStillState() {
    _warmUpgradeTimer?.cancel(); // Cancel upgrade timer if user stops moving

    if (_currentMode == AdaptiveScanMode.WARM) {
      // Start the 5-min buffer to downgrade to COLD if not already running
      if (_coldTimer == null || !_coldTimer!.isActive) {
        _coldTimer = Timer(BGService.coldBufferDuration, () {
          debugPrint("[AdaptiveScan] Still for 5 mins. Downgrading to COLD.");
          _setMode(AdaptiveScanMode.COLD);
        });
      }
    }
  }

  Future<void> _handleMotionState(double avgMagnitude) async {
    // Cancel the COLD downgrade timer since user moved
    _coldTimer?.cancel();

    if (_currentMode == AdaptiveScanMode.COLD) {
      // Start the 10-second upgrade timer if not already running
      if (_warmUpgradeTimer == null || !_warmUpgradeTimer!.isActive) {
        debugPrint(
            "[AdaptiveScan] Initial motion detected. Starting 10s WARM upgrade timer.");
        _warmUpgradeTimer = Timer(BGService.warmUpgradeDuration, () async {
          debugPrint(
              "[AdaptiveScan] Motion sustained for 10s -> Upgrading to WARM.");
          _setMode(AdaptiveScanMode.WARM);
          await _checkSpeedToUpgradeHot();
        });
      }
    } else if (_currentMode == AdaptiveScanMode.WARM) {
      // Check speed to potentially upgrade to HOT, but rely on the throttle
      // built into the check function so we don't spam GPS.
      await _checkSpeedToUpgradeHot();
    }
  }

  // ── GPS Logic ─────────────────────────────────────────────────────────────

  /// ตรวจสอบความเร็วผ่านดาวเทียม GPS เพื่ออัปเกรดขึ้นโหมด "ดุเดือด" (HOT Mode)
  /// 
  /// **Business Logic (The "Why"):**
  /// ไม่สามารถยิง GPS รัวๆ ได้เพราะกินไฟมาก และ Google อาจโยน Exception กลับมา
  /// จึงทำกลไก Hard Throttle ว่า `จะเช็ค GPS แค่ 1 ครั้งในทุกๆ 30 วินาที เท่านั้น`
  /// เมื่อเช็คความเร็วได้แล้ว นำมาแปลงเป็น กิโลเมตร/ชั่วโมง หากพบว่าเกิน 20km/h (ความเร็วรถ) ให้ดีดเป็นโหมด HOT
  Future<void> _checkSpeedToUpgradeHot() async {
    if (_isCheckingSpeed || _currentMode == AdaptiveScanMode.HOT) return;

    // Hard Throttle: Do not check GPS more than once every 30 seconds
    final now = DateTime.now();
    if (now.difference(_lastSpeedCheckTime) < _speedCheckThrottleLimit) {
      return;
    }

    _isCheckingSpeed = true;
    _lastSpeedCheckTime = now;

    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 20, // ไม่ต้องเก็บทุกเมตร เอาทุก 20 เมตรก็พอ
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Checking your driving location...",
          notificationTitle: "Bearcon Active",
        ),
      ));

      double speedKmh = position.speed * 3.6;

      if (speedKmh > BGService.speedThresholdHot) {
        debugPrint("[AdaptiveScan] Speed > 20km/h -> Upgrading to HOT.");
        _setMode(AdaptiveScanMode.HOT);
      }
    } catch (e) {
      // Fallback: stay in WARM if GPS fails
      debugPrint("[AdaptiveScan] GPS Check failed: $e. Remaining in WARM.");
    } finally {
      // Debounce via timer as a secondary safeguard
      _hotCooldownTimer = Timer(const Duration(seconds: 30), () {});
      _isCheckingSpeed = false;
    }
  }

  /// ตรวจสอบเพื่อลดระดับชั้นจาก Driving (HOT) กลับไปเป็น Walking (WARM)
  /// 
  /// **Business Logic (The "Why"):**
  /// โหมดยากสุดของการแทรค GPS คือเวลารถติดไฟแดง ความเร็วจะเป็น 0km/h ชั่วคราว
  /// ระบบจึงสร้างลอจิกเช็คความเร็วแบบ `Double Count` (_lowSpeedCount)
  /// ต้องรถหยุด หรือคลาน ต่ำกว่า 20km/h ติดต่อกันถึง "3 รอบเช็ค" (ประมาณ 3 นาที) 
  /// จึงจะมั่นใจว่าจอดรถแน่ๆ แล้วถึงจะลดระดับไปเป็นโหมด WARM
  Future<void> _checkDowngradeFromHot() async {
    if (_currentMode != AdaptiveScanMode.HOT) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          // ใช้ Low หรือ Medium ก็เพียงพอสำหรับการเช็ค Speed รถ
          accuracy: LocationAccuracy.medium,

          // สำคัญมาก: ในการเช็ค Speed ไม่ควรตั้ง distanceFilter สูงเกินไป
          // เพราะถ้าเราจอดรถติดไฟแดง รถไม่ขยับ (distance = 0)
          // ตัว Geolocator อาจจะไม่คืนค่าใหม่ให้ หรือคืนค่าเก่ามา
          distanceFilter: 0,

          // ตั้งค่าเวลาที่ยอมให้รอคอยสัญญาณ
          timeLimit: const Duration(seconds: 5),

          // บอกระบบว่าขอข้อมูลทุกๆ กี่วินาที (สำหรับ Background)
          intervalDuration: const Duration(seconds: 10),
        ),
      );

      double speedKmh = position.speed * 3.6;

      // ตัวอย่าง Logic ที่นิ่งขึ้น
      if (speedKmh < BGService.speedThresholdHot) {
        _lowSpeedCount++;
        if (_lowSpeedCount >= 3) {
          // ต้องความเร็วต่ำติดต่อกัน 3 รอบเช็ค
          _setMode(AdaptiveScanMode.WARM);
          _lowSpeedCount = 0;
        }
      } else {
        _lowSpeedCount = 0; // ถ้ากลับมาเร็วใหม่ ให้รีเซ็ตตัวนับ
      }
    } catch (e) {
      debugPrint("[AdaptiveScan] HOT Downgrade check failed: $e");
    }
  }

  // ── Mode Management ───────────────────────────────────────────────────────

  void _setMode(AdaptiveScanMode newMode) {
    if (_currentMode == newMode) return;

    // Cleanup old mode timers
    if (_currentMode == AdaptiveScanMode.HOT) {
      _hotCooldownTimer?.cancel();
    }
    _coldTimer?.cancel();
    _warmUpgradeTimer?.cancel();

    // Setup new mode timers
    if (newMode == AdaptiveScanMode.HOT) {
      _lowSpeedCount = 0; // Reset count when entering HOT mode
      // While in HOT, check speed periodically. If low speed persists > 1 min, downgrade.
      _hotCooldownTimer =
          Timer.periodic(BGService.hotCooldownDuration, (_) async {
        await _checkDowngradeFromHot();
      });
    }

    _currentMode = newMode;
    onModeChanged?.call(_currentMode);

    // Restart scanning behaviors immediately
    _startScanCycle();
  }

  // ── Scanning Cycles ───────────────────────────────────────────────────────

  void _startScanCycle() {
    _scanCycleTimer?.cancel();
    onStopScan(); // Stop any currently active scan loop

    if (_currentMode == AdaptiveScanMode.HOT) {
      // HOT: Every 30 seconds for 5s
      _runPeriodicScan(
          interval: BGService.hotScanInterval,
          duration: BGService.hotScanDuration);
    } else if (_currentMode == AdaptiveScanMode.WARM) {
      // WARM: Every 3 min for 15s
      _runPeriodicScan(
          interval: BGService.warmScanInterval,
          duration: BGService.warmScanDuration);
    } else if (_currentMode == AdaptiveScanMode.COLD) {
      // COLD: Every 5 mins for 30s
      _runPeriodicScan(
          interval: BGService.coldScanInterval,
          duration: BGService.coldScanDuration);
    }
  }

  // void _runContinuousScanLoop() async {
  //   _continuousRunFlag = true;
  //   while (_isRunning &&
  //       _continuousRunFlag &&
  //       _currentMode == AdaptiveScanMode.HOT) {
  //     // Scan for a bulk period (e.g. 60s), process, then repeat safely.
  //     await onTriggerScan(const Duration(seconds: 60));
  //     // Add a tiny delay to allow task switching/cancellation to process
  //     await Future.delayed(const Duration(milliseconds: 100));
  //   }
  // }

  void _runPeriodicScan(
      {required Duration interval, required Duration duration}) {
    // Run immediately when mode changes
    _executeSingleScan(duration);

    _scanCycleTimer = Timer.periodic(interval, (_) {
      _executeSingleScan(duration);
    });
  }

  void _executeSingleScan(Duration duration) async {
    if (!_isRunning) return;
    await onTriggerScan(duration);
  }
}
