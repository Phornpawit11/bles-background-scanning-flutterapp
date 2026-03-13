import 'dart:async';
import 'package:bearcon_card_app/utils/bgservice.key.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../infrastructure/service/adaptive_scan_service.dart';
import '../../domain/request/locationsend.request.dart';
import '../../infrastructure/service/logger_service.dart';
import '../../infrastructure/service/thedot.service.dart';
import '../../utils/ibeacon_parser.dart';

/// ตัวควบคุมหลัก (Controller) สำหรับการทำงานในส่วนของเครื่องดักฟังเบื้องหลัง (Background Isolate)
///
/// **หน้าที่หลัก (Responsibilities):**
/// เป็นศูนย์กลางสั่งงาน [AdaptiveScanService] และรับผลลัพธ์ว่าเจอบีคอนตัวไหนบ้าง
/// จากนั้นจะโยงเข้าสู่ระบบยิงพิกัดไปรวบรวมส่งให้ 서버หลักของระบบ The Dot ([ThedotService])
///
/// **Business Logic (The "Why"):**
/// เนื่องจาก Service เหล่านี้ทำงาน 24 ชั่วโมง เราจึงดีไซน์โดยยึดหลัก Clean Code
/// - แยกการตั้งค่าแพ็กเกจออกไป (`background_ble_service.dart`)
/// - นำสมอง (Logic) มาฝังไว้ที่นี่
/// - ใช้กลไก `_cooldowns` แบบ HashMap เพื่อจำว่า "บีคอนตัวนี้เพิ่งส่งข้อมูลไปนะ" ถ้ามีคนเดินผ่านอีกใน 10 นาที ก็ไม่ต้องยิงซ้ำ ประหยัดเน็ต
class BackgroundBleController extends GetxController {
  final _ble = FlutterReactiveBle();
  final LoggerService _logger = Get.find<LoggerService>();

  bool isServiceRunning = true;
  bool _isScanningRunning = false;
  AdaptiveScanMode _currentMode = AdaptiveScanMode.COLD;
  AdaptiveScanService? _adaptiveScanner;
  StreamSubscription? _activeScanSubscription;

  final Map<String, DateTime> _cooldowns = {};

  // Last known tags to ensure reporting even if scan misses a cycle
  final Set<String> _lastKnownUuids = {};
  final Set<String> _lastKnownNames = {};

  List<String> _allowedPrefixes = ['PB713'];

  /// ปลุกระบบประหยัดแบตเตอรี่ (Adaptive Scanner) ให้เริ่มทำงาน
  ///
  /// **Business Logic (The "Why"):**
  /// จะมีการโหลดค่า `allowedModels` จาก SharedPreferences เพื่อดูว่าผู้ใช้กรอกฟิลเตอร์รุ่นไหนไว้
  /// รุ่นที่ไม่ผ่านเกณฑ์ จะถูกทิ้งก่อนนำมาคำนวณเลย ช่วยตัดปัญหาขยะขึ้นเซิร์ฟเวอร์
  Future<void> startAdaptiveScanning() async {
    _logger.addLog("Starting Adaptive Scanner setup...", type: 'INFO');

    final prefs = await SharedPreferences.getInstance();
    final savedModels = prefs.getStringList('allowed_device_models');
    if (savedModels != null && savedModels.isNotEmpty) {
      _allowedPrefixes = savedModels;
    }
    _logger.addLog("Allowed Models: ${_allowedPrefixes.join(', ')}",
        type: 'INFO');

    _adaptiveScanner = AdaptiveScanService(
      onTriggerScan: _executeScanPhase,
      onStopScan: _cancelActiveScan,
      onModeChanged: _handleModeChanged,
    );
    _adaptiveScanner!.start();
  }

  void _handleModeChanged(AdaptiveScanMode mode) {
    _currentMode = mode;
    _logger.addLog("Scan Mode changed to: ${mode.name}", type: 'INFO');

    // Sync mode to UI
    _logger.serviceInstance?.invoke('updateMode', {'mode': mode.name});
    _updateAndroidNotification("Mode: ${mode.name}");
  }

  void stop() {
    isServiceRunning = false;
    _adaptiveScanner?.stop();
    _activeScanSubscription?.cancel();
    _logger.addLog("Adaptive Scanner stopped.", type: 'WARNING');
  }

  void _cancelActiveScan() {
    _activeScanSubscription?.cancel();
    _isScanningRunning = false;
  }

  void _cleanUpStaleCooldowns() {
    final now = DateTime.now().toUtc();
    _cooldowns.removeWhere((key, lastSent) =>
        now.difference(lastSent).inMinutes >= BGService.cooldownMinutes);
  }

  /// เปิดกล้อง Bluetooth ประจำรอบ (Scan Cycle) และดักจับ UUID ที่เจอ
  ///
  /// **พารามิเตอร์ [scanDuration]:** ความยาวนานของรอบนี้ (เช่น 15 วินาที, หรือ 30 วินาที ขึ้นกับโหมดเดิน/ขับรถ)
  ///
  /// **Business Logic (The "Why"):**
  /// 1. เช็คสภาวะ Bluetooth เสมอ เพราะผู้ใช้อาจเผลอปิดระหว่างแอปหลับ
  ///    (หากรอโดยครอบ `await _ble.statusStream` แอปอาจจะเกิด Deadlock ไปเลย จึงต้องตรวจสเตตัสแบบ Snapshot แทน)
  /// 2. เปิดโหมด `ScanMode.lowPower` (สแกนแบบเน้นประหยัดแบตเตอรี่ แต่อาจจะดีเลย์วิสองวิ)
  ///    และจะเล็งหา UUID `FEE9` เป็นหลักเพื่อเข้าหัวใจของบีคอน
  /// 3. รวบรวมรายชื่อ (`Set`) คนที่เจอทั้งหมดภายในเวลา [scanDuration]
  /// 4. ส่งตะกร้ารายชื่อไปแพ็กส่งพิกัดพร้อมกันทีเดียว (`_sendBatchReport`)
  Future<void> _executeScanPhase(Duration scanDuration) async {
    if (!isServiceRunning || _isScanningRunning) return;

    if (_ble.status != BleStatus.ready) {
      _logger.addLog("Scan Skipped: Bluetooth is not ready", type: 'WARNING');
      return;
    }

    _cleanUpStaleCooldowns();

    _isScanningRunning = true;

    _logger.addLog(
      "📡 Scanning for ${scanDuration.inSeconds} seconds...",
      type: 'INFO',
    );

    final Set<String> discoveredUuidsInCycle = {};
    final Set<String> deviceNamesInCycle = {};

    // 1. Active Scan Phase
    try {
      _activeScanSubscription = _ble.scanForDevices(
          withServices: [Uuid.parse("FEE9")],
          scanMode: ScanMode.lowPower).listen(
        (device) => _handleDiscoveredDevice(
          device,
          discoveredUuidsInCycle,
          deviceNamesInCycle,
        ),
        onError: (e) => _logger.addLog("Scan error: $e", type: 'ERROR'),
      );

      await Future.delayed(scanDuration);
    } finally {
      await _activeScanSubscription?.cancel();
      _isScanningRunning = false;
    }

    // 2. Process Findings
    if (discoveredUuidsInCycle.isEmpty) {
      _handleNoTagsFound(discoveredUuidsInCycle, deviceNamesInCycle);
    } else {
      _updateLastKnownTags(discoveredUuidsInCycle, deviceNamesInCycle);
    }

    _updateAndroidNotification(
        "Mode: ${_currentMode.name} • Tags: ${discoveredUuidsInCycle.length}");

    // 3. Batch Send to Server
    if (discoveredUuidsInCycle.isNotEmpty) {
      await _sendBatchReport(discoveredUuidsInCycle.toList());
    }
  }

  void _updateAndroidNotification(String subtext) {
    _logger.serviceInstance?.invoke('updateSubtext', {'subtext': subtext});
  }

  void _handleDiscoveredDevice(
    DiscoveredDevice device,
    Set<String> discoveredUuids,
    Set<String> deviceNames,
  ) {
    final bool isAllowed =
        _allowedPrefixes.any((prefix) => device.name.startsWith(prefix));
    if (isAllowed && isServiceRunning) {
      final parsedData = IBeaconData.parse(device.manufacturerData);
      if (parsedData != null) {
        final String uuid = parsedData.uuid;
        final now = DateTime.now().toUtc();
        final lastSent = _cooldowns[uuid];

        if (lastSent == null ||
            now.difference(lastSent).inMinutes >= BGService.cooldownMinutes) {
          discoveredUuids.add(uuid);
          deviceNames.add(device.name);
          _cooldowns[uuid] = now;
        }
      }
    }
  }

  void _handleNoTagsFound(
    Set<String> discoveredUuids,
    Set<String> deviceNames,
  ) {
    _logger.addLog(
      "No active tags found in range. (Ghost tracking API disabled)",
      type: 'WARNING',
    );
    // DO NOT add _lastKnownUuids to discoveredUuids to prevent Ghost Tracking API requests
  }

  void _updateLastKnownTags(
    Set<String> discoveredUuids,
    Set<String> deviceNames,
  ) {
    _lastKnownUuids.clear();
    _lastKnownUuids.addAll(discoveredUuids);
    _lastKnownNames.clear();
    _lastKnownNames.addAll(deviceNames);

    _logger.addLog(
      "Matched Tags: ${deviceNames.join(', ')}",
      type: 'INFO',
    );
  }

  /// มัดรวมพิกัด (Batch) ของ UUID ที่เพิ่งค้นเจอ แล้วสั่งยิงส่ง API
  ///
  /// **พารามิเตอร์ [uuids]:** รายชื่อ UUID ที่ผ่านการกรอง Cooldown และ Filter มาแล้ว
  ///
  /// **Business Logic (The "Why"):**
  /// - จะปรับความแม่นยำของดาวเทียมยืดหยุ่นตาม [AdaptiveScanMode] เพื่อไม่ให้เปลืองแบต
  ///   (สมมติอยู่นิ่งๆ กินข้าว ไม่ต้องขอพิกัดแม่นยำมากเพราะอยู่ในตึก)
  /// - ทำการตัดซอยคำขอ (Chunk) ให้ส่งแบบขนาน (Parallel) ทีละ "5 เครื่อง" ป้องกันการยิง
  ///   API ถล่มทลาย (DDoS Effect)
  /// - ตั้งเวลาอนุญาตให้ร้องขอ GPS (timeLimit) ไว้ที่ 10 วินาที ถ้าหาตำแหน่งไม่เจอก็จะยกเลิก
  ///   เพราะเราไม่อยากให้ Android Isolate ค้างเติ่งรอตลอดกาล
  Future<void> _sendBatchReport(List<String> uuids) async {
    try {
      _logger.addLog("Fetching location for batch report...", type: 'INFO');

      LocationAccuracy accuracy = LocationAccuracy.low;
      if (_currentMode == AdaptiveScanMode.HOT) {
        accuracy = LocationAccuracy.high;
      } else if (_currentMode == AdaptiveScanMode.WARM) {
        accuracy = LocationAccuracy.medium;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            // แนะนำ Accuracy: High เฉพาะในโหมด HOT หรือ WARM
            // เพื่อให้ตำแหน่งบนแผนที่ "เกาะถนน" และไม่กระโดดไปมา
            accuracy: accuracy,

            // distanceFilter: 0
            // ใน Batch Report เราต้องการตำแหน่งล่าสุด ณ วินาทีนั้นจริงๆ
            // แม้จะหยุดรถอยู่ที่เดิม ตำแหน่งเดิมก็ยังสำคัญในการยืนยันว่า Tag ยังอยู่ที่นี่
            distanceFilter: 0,

            // timeLimit: 8-10 seconds
            // การดึงพิกัดแบบ High อาจใช้เวลาค้นหาสัญญาณดาวเทียม (GPS Fix)
            // นานกว่าแบบ Medium เล็กน้อย จึงควรเพิ่มเวลาให้ระบบทำงานได้สำเร็จ
            timeLimit: const Duration(seconds: 10),

            intervalDuration: const Duration(seconds: 10),
          ),
        );
      } catch (e) {
        _logger.addLog("GPS fetch timeout or error: $e. Batch skipped.",
            type: 'WARNING');
        return;
      }

      final timestamp = DateTime.now().toUtc();
      final String gpsTime = _formatGpsTime(timestamp);

      _logger.addLog(
        "Location: ${position.latitude}, ${position.longitude}",
        type: 'INFO',
      );

      // Process in chunks to prevent API spiking (DDoS effect)
      const int batchSize = 5;
      for (int i = 0; i < uuids.length; i += batchSize) {
        final chunk = uuids.sublist(
            i, i + batchSize > uuids.length ? uuids.length : i + batchSize);

        final List<Future<void>> apiRequests = chunk
            .map((uuid) => _sendSingleRequest(uuid, position!, gpsTime))
            .toList();

        await Future.wait(apiRequests);
      }

      _logger.addLog(
        "Batch sent ${uuids.length} tags successfully.",
        type: 'SUCCESS',
      );
    } catch (e) {
      _logger.addLog("Batch location/reporting error: $e", type: 'ERROR');
    }
  }

  Future<void> _sendSingleRequest(
    String uuid,
    Position pos,
    String gpsTime,
  ) async {
    try {
      final request = LocationSendRequest(
        imei: uuid,
        lat: pos.latitude,
        lng: pos.longitude,
        speed: pos.speed > 0 ? pos.speed : 0.0,
        direction: pos.heading.toInt(),
        gpsTime: gpsTime,
        batteryPowerVal: 100.0,
      );

      final response = await ThedotService.create().sendLocation(
        apiKey: BGService.tracksolidApiKey,
        requestBody: request,
      );

      _logger.addLog("API SUCCESS -> $uuid sent. Status: ${response.status}",
          type: 'INFO');
    } catch (e) {
      _logger.addLog("Request error for $uuid: $e", type: 'ERROR');
    }
  }

  String _formatGpsTime(DateTime t) {
    return "${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} "
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}";
  }
}
