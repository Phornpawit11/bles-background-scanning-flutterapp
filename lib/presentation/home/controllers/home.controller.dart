import 'dart:async';
import 'dart:io';
// import 'dart:convert';
import 'package:bearcon_card_app/utils/ibeacon_parser.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/dumb_widgets/confirm_delete_dialog.dart';

import 'package:bearcon_card_app/domain/models/tag_card.dart';

/// คลาส [HomeController] เป็นศูนย์กลางการควบคุมหลักของหน้า Home
/// 
/// **หน้าที่หลัก (Responsibilities):**
/// 1. จัดการข้อมูล Tag ที่บันทึกไว้ (`registeredTags`) และ Tag ที่กำลังเชื่อมต่อดึงข้อมูลสด (`connectedTags`)
/// 2. ตรวจสอบและขอ State ของ Permission ทั้งระบบ (Location, Bluetooth, Notification)
/// 3. จัดการสถานะการเปิด/ปิด Background Service (Isolate)
/// 4. จัดการสแกนหาอุปกรณ์ใหม่ (`addTag`) แบบ Manual
/// 
/// **Business Logic (The "Why"):**
/// HomeController อาศัยหลักการของ GetX Controller เพื่อควบคุม UI State ข้ามหน้าจอต่างๆ 
/// การแยกลอจิกออกมาที่นี่ทำให้ไฟล์ `home.screen.dart` สะอาดขึ้น 
/// และแชร์สถานะ `connectedTags` หรือ `bleStatus` ไปให้ Widget ย่อยๆ (เช่น แท็บเพิ่มแท็ก) รับรู้ได้ทันที
class HomeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  /// ตัวควบคุมช่องค้นหา MAC Address หรือชื่อบลูทูธสำหรับการแอดเข้าแอป
  final TextEditingController macAddressController = TextEditingController();
  /// รายการ Tag ที่ผู้ใช้บันทึกไว้ในระบบ
  final RxList<TagCard> registeredTags = <TagCard>[].obs;
  
  /// รายการ Tag ที่กำลังเชื่อมต่อ (Connected) กับเครื่อง ณ เวลานี้เพื่ออ่านค่า Battery
  final RxList<TagCard> connectedTags = <TagCard>[].obs;
  
  /// สถานะบ่งบอกว่า Background Service ກຳลังทำงานอยู่หรือไม่
  final RxBool isServiceRunning = false.obs;
  
  /// สถานะป้องกันการกดปุ่มสวิตช์ Background Service รัวๆ (Debounce UI)
  final RxBool isTogglingService = false.obs;
  
  /// สถานะบอกว่าแอปกำลังเข้าสู่โหมดสแกนหาอุปกรณ์ใหม่เพื่อเพิ่มเข้าระบบ (Active Scanning หน้าบ้าน)
  final RxBool isScanningForAdd = false.obs;
  
  final RxList<DiscoveredDevice> foundTags = <DiscoveredDevice>[].obs;
  final RxString version = ''.obs;

  /// เก็บสถานะการเข้าถึง Bluetooth ของระบบ
  /// - `checking`: กำลังตรวจสอบ
  /// - `denied`: ผู้ใช้ปฏิเสธการให้สิทธิ์
  /// - `off`: เครื่องปิดบลูทูธ (ฮาร์ดแวร์) หรือ Location อยู่
  /// - `granted`: พร้อมใช้งานแบบ 100%
  final RxString bleStatus = 'checking'.obs;

  // Pulse animation for the "Searching..." AppBar title
  late final AnimationController pulseCtrl;
  late final Animation<double> pulseAnimation;

  final Map<String, StreamSubscription<ConnectionStateUpdate>>
      _connectionSubscriptions = {};
  final RxMap<String, DeviceConnectionState> deviceStates =
      <String, DeviceConnectionState>{}.obs;

  StreamSubscription<DiscoveredDevice>? _scanSubscription;

  @override
  void onInit() {
    super.onInit();
    // _loadTags();
    _checkServiceStatus();
    _initPackageInfo();
    // Initialize pulse animation for "Searching..." title
    pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void onReady() {
    super.onReady();
    retryBlePermissions();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    version.value = info.version;
  }

  /// Checks BLE + permission status and updates [bleStatus] reactively.
  /// Can be called from the UI to retry after permissions are changed.
  Future<void> retryBlePermissions() async {
    bleStatus.value = 'checking';
    final granted = await requestBlePermissions();
    bleStatus.value = granted ? 'granted' : bleStatus.value;
  }

  Future<void> _checkServiceStatus() async {
    final service = FlutterBackgroundService();
    isServiceRunning.value = await service.isRunning();
  }

  /// ฟังก์ชันหลักสุดโหดสำหรับการขอ Permission แบบเรียงลำดับ (Sequential)
  /// 
  /// **คืนค่า (Returns):** `true` หากได้สิทธิ์ครบทุกด่านและพร้อมเริ่ม Service, ส่วน `false` หากติดค้างหน้าไหนสักหน้า
  /// 
  /// **Business Logic (The "Why"):**
  /// ลำดับการขอสิทธิ์เป็นสิ่งสำคัญมากใน Flutter OS:
  /// 1. Android 13+ จำเป็นต้องขอ Notification ก่อนเป็นอันดับแรก (เพื่อแสดง Foreground Notification)
  /// 2. ต้องเช็คว่าผู้ใช้เปิด GPS สวิตช์ฮาร์ดแวร์หรือไม่ (Location Services) เพราะถ้าปิด จะมองไม่เห็น BLE เลย
  /// 3. เมื่อเปิดแล้ว ต้องขอสิทธิ์ Location แบบ `WhenInUse` ก่อน จากนั้นถึงจะขยับไปขอ `Always` ได้ (นพโยบาย Android/iOS ล่าสุดบังคับ)
  /// 4. สุดท้ายจึงเข้าสู่การขอสิทธิ์ของ Bluetooth โดยแยกตาม OS (iOS ขอแค่ก้อนเดียว ส่วน Android 12+ ต้องขอ Scan/Connect แยก)
  /// หากมีจุดไหนพลาด จะแสดง Dialog หรือ Snackbar แจ้งเตือนสาเหตุอย่างเจาะจง เพื่อให้ UX ไม่สับสน
  Future<bool> requestBlePermissions() async {
    if (Platform.isAndroid) {
      // 🚨 0. ขอสิทธิ์ Notification (สำหรับ Android 13+)
      PermissionStatus notifStatus = await Permission.notification.request();

      // ✅ เช็ค Permanently Denied ก่อน
      if (notifStatus.isPermanentlyDenied) {
        Get.snackbar(
          'ถูกปิดกั้นการแจ้งเตือน',
          'กรุณาไปที่หน้าตั้งค่า (Settings) เพื่อเปิดสิทธิ์การแจ้งเตือนด้วยตัวเองครับ',
          backgroundColor: Colors.orange.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        await openAppSettings();
        return false;
      }

      // ✅ ค่อยเช็คว่าไม่ได้รับสิทธิ์ธรรมดา
      if (!notifStatus.isGranted) {
        Get.snackbar(
          'Notification Required',
          'Please allow notifications to run the background service.',
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
        return false;
      }
    }

    // 1. Check if GPS hardware is turned ON
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      bleStatus.value = 'off';
      Get.snackbar(
        'Location Required',
        'Please turn on GPS/Location Services to scan for Bluetooth devices.',
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return false;
    }

    // 2. Request LocationWhenInUse first
    PermissionStatus locStatus = await Permission.locationWhenInUse.request();
    if (locStatus.isPermanentlyDenied) {
      bleStatus.value = 'denied';
      return false;
    }
    if (!locStatus.isGranted) {
      bleStatus.value = 'denied';
      _showPermissionError();
      return false;
    }

    // 3. Request LocationAlways (✅ เพิ่มการเช็คผลลัพธ์)
    PermissionStatus locAlwaysStatus =
        await Permission.locationAlways.request();
    if (!locAlwaysStatus.isGranted) {
      bleStatus.value = 'denied';
      Get.snackbar(
        'Background Location Required',
        'Please select "Allow all the time" for background tracking.',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      // ถ้าไม่ได้สิทธิ์ Always อาจจะบังคับพาไป Settings
      // await openAppSettings();
      return false;
    }

    // 4. Request BLE Permissions & Wait for Bluetooth
    try {
      Map<Permission, PermissionStatus> bleStatuses;

      if (Platform.isIOS) {
        // 🍎 iOS
        bleStatuses = await [Permission.bluetooth].request();
      } else {
        // 🤖 Android 12+
        bleStatuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();
      }

      if (bleStatuses.values.any((status) => status.isPermanentlyDenied)) {
        debugPrint("[BLE Permission] Permanently Denied: $bleStatuses");
        bleStatus.value = 'denied';
        return false;
      }

      if (bleStatuses.values
          .any((status) => !status.isGranted && !status.isRestricted)) {
        debugPrint("[BLE Permission] Denied: $bleStatuses");
        bleStatus.value = 'denied';
        _showPermissionError();
        return false;
      }

      // รอให้ Bluetooth พร้อมทำงาน
      await FlutterReactiveBle()
          .statusStream
          .where((state) => state == BleStatus.ready)
          .first;
    } catch (e) {
      bleStatus.value = 'off';
      Get.snackbar(
        'Bluetooth Required',
        'Please turn on Bluetooth.',
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return false; // ✅ เพิ่ม return false ตรงนี้
    }

    return true; // ✅ ผ่านทุกด่าน! พร้อมสตาร์ท Service
  }

  void _showPermissionError() {
    Get.snackbar(
      'Permissions Required',
      'Please grant Location and Bluetooth permissions to use this app.',
      backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
      colorText: Colors.white,
    );
  }

  /// สลับการทำงานของคำสั่งดักฟังพื้นหลัง (Background Isolate)
  /// 
  /// **พารามิเตอร์ [value]:** `true` หากคลิกให้เปิดการทำงาน, `false` หากต้องการปิด
  /// 
  /// **Business Logic (The "Why"):**
  /// ไม่สามารถสั่งเปิดได้เลยจนกว่าจะได้ Permission 100% (ผ่านการเช็ค [requestBlePermissions])
  /// นอกจากนี้ ยังมีการหน่วงเวลา (Delay 500ms) ก่อนอัปเดต UI หลังจากเรียก API พื้นหลัง
  /// เพื่อป้องกันปัญหา UI ชิ้งอัปเดทไวกว่าที่ Service บน Android เปลี่ยน State จริง
  void toggleBackgroundService(bool value) async {
    try {
      isTogglingService.value = true;
      final service = FlutterBackgroundService();
      if (value) {
        bool hasPermissions = await requestBlePermissions();
        if (!hasPermissions) {
          isServiceRunning.value = false;
          isTogglingService.value = false;
          return;
        }
        await service.startService();
      } else {
        service.invoke('stopService');
      }
      // Give it a moment to change state
      Future.delayed(const Duration(milliseconds: 500), () async {
        await _checkServiceStatus();
        isTogglingService.value = false;
      });
    } catch (e) {
      debugPrint("ERROR:${e.toString()}");
    } finally {
      isTogglingService.value = false;
    }
  }

  /// ระบบสแกนหา Beacon สดๆ หน้าบ้าน (Foreground Active Scan)
  /// 
  /// **วิธีการทำงาน:**
  /// 1. ปิดแป้นพิมพ์ และล้างข้อมูลชั่วคราวออก
  /// 2. ตรวจสอบสิทธิ์ BLE ทั้งหมดอีกครั้งก่อนเริ่ม
  /// 3. สานต่อการสแกนผ่าน [FlutterReactiveBle] ด้วยโหมด `lowLatency` (กินแบตสุด แต่เจอเร็วสุด เพราะผู้ใช้ถือจอรออยู่)
  /// 4. ตรวจสอบเงื่อนไขว่า "ตรงกับคำที่พิมพ์หา" ไหม หรือ "เป็นรุ่นที่เราอนุญาตผ่าน Settings" ไหม ([allowedModels])
  /// 5. หากตรงเงื่อนไข -> จับเพิ่มเข้าก้อนข้อมูล `registerNewTag(...)` 
  /// 6. ตัดการทำงานอัตโนมัติภายใน 60 วินาที เพื่อไม่ให้แบตหมด (Timeout Handle)
  void addTag() async {
    isScanningForAdd.value = true;
    FocusManager.instance.primaryFocus?.unfocus();
    registeredTags.clear();

    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    bool hasPermissions = await requestBlePermissions();
    if (!hasPermissions) {
      isScanningForAdd.value = false;
      return;
    }

    // Start real FlutterReactiveBle scanning
    final ble = FlutterReactiveBle();
    final searchText = macAddressController.text.trim().toUpperCase();

    final prefs = await SharedPreferences.getInstance();
    final savedModels = prefs.getStringList('allowed_device_models');
    final List<String> allowedModels =
        (savedModels != null && savedModels.isNotEmpty)
            ? savedModels
            : ['PB713'];

    _scanSubscription = ble.scanForDevices(
        withServices: [], scanMode: ScanMode.lowLatency).listen((device) {
      final name = device.name.toUpperCase();
      final id = device.id.toUpperCase();

      // 1. ตรวจสอบว่าตรงกับคำค้นหาหรือไม่ (เฉพาะเมื่อมีการพิมพ์คำค้นหา)
      bool isMatchSearch = searchText.isNotEmpty &&
          (name.isNotEmpty && name.contains(searchText) ||
              id.isNotEmpty && id.contains(searchText));

      // 2. ตรวจสอบเงื่อนไขพื้นฐาน (ขึ้นต้นด้วย prefix ที่กำหนดใน Settings)
      bool isDefaultTag =
          allowedModels.any((prefix) => name.startsWith(prefix));

      if (isMatchSearch || isDefaultTag) {
        registerNewTag(device);
      }
    });

    // Auto-stop scanning after 15 seconds real or simulated
    Future.delayed(const Duration(seconds: 60), () {
      if (isScanningForAdd.value) {
        stopAdditionScanning();
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      }
    });
  }

  void stopAdditionScanning() {
    isScanningForAdd.value = false;
    _scanSubscription?.cancel();
  }

  void registerNewTag(DiscoveredDevice device) {
    if (registeredTags.any((t) => t.macAddress == device.id)) {
      return;
    } else {
      final parsedData = IBeaconData.parse(device.manufacturerData);
      if (parsedData != null) {
        final newCard = TagCard(
          id: parsedData.uuid,
          name: device.name,
          macAddress: device.id,
          batteryPercentage: 100, // Dummy battery since we parse MAC mostly
        );

        registeredTags.add(newCard);
        // _saveTags();
      }
    }
  }

  /// สั่งเครื่องให้ทำการสื่อสารโดยตรงผ่านระบบ GATT กับ BLE Beacon ที่ระบุตาม [id] (MAC / UUID)
  /// 
  /// **พารามิเตอร์ [id]:** MAC Address หรือ UUID ของบีคอนที่เห็นอยู่ในอากาศ
  /// 
  /// **Business Logic (The "Why"):**
  /// เมื่อ Tag เชื่อมต่อติดแล้ว เราจะเรียก `_readBatteryLevel(id)` โดยทันที
  /// นี่คือเหตุผลว่าทำไมถึงต้องมีการ Connect ไม่ใช่อ่านแค่โฆษณา (Ad-Packet) ลอยๆ
  /// เพราะบางครั้งผู้สร้าง Firmware ซ่อน Service `180f` ไว้ให้ต้อง Connect ก่อนจึงจะอ่านออก
  void connectToTag(String id) {
    if (_connectionSubscriptions.containsKey(id)) return;

    final ble = FlutterReactiveBle();
    deviceStates[id] = DeviceConnectionState.connecting;

    final subscription = ble
        .connectToDevice(id: id, connectionTimeout: const Duration(seconds: 15))
        .listen(
      (state) {
        debugPrint(
          "[BLE Connection] State for $id: ${state.connectionState}",
        );
        deviceStates[id] = state.connectionState;
        if (state.connectionState == DeviceConnectionState.connected) {
          final index = registeredTags.indexWhere(
            (tag) => tag.macAddress == id,
          );
          if (index != -1) {
            final tag = registeredTags.removeAt(index);
            connectedTags.add(tag);
            Get.snackbar(
              'Connected',
              'Successfully connected to ${tag.name}',
            );
            // 🔋 Read battery level after successful connection
            _readBatteryLevel(id);
          }
        } else if (state.connectionState ==
            DeviceConnectionState.disconnected) {
          _handleDisconnect(id);
        }
      },
      onError: (e) {
        debugPrint("[BLE Connection] Error for $id: $e");
        _handleDisconnect(id);
        Get.snackbar('Connection Error', 'Failed to connect: $e');
      },
    );

    _connectionSubscriptions[id] = subscription;

    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  void _handleDisconnect(String id) {
    _connectionSubscriptions[id]?.cancel();
    _connectionSubscriptions.remove(id);
    deviceStates.remove(id);

    final index = connectedTags.indexWhere((tag) => tag.macAddress == id);
    if (index != -1) {
      final tag = connectedTags.removeAt(index);
      registeredTags.add(tag);
      Get.snackbar('Disconnected', '${tag.name} disconnected.');
    }
  }

  void disconnectTag(String id) {
    _handleDisconnect(id);
  }

  /// อ่านค่าเปอร์เซ็นต์แบตเตอรี่ล่าสุดจากอุปกรณ์
  /// 
  /// **พารามิเตอร์ [deviceId]:** รหัสอุปกรณ์เป้าหมายที่เชื่อมต่อเรียบร้อยแล้ว
  /// 
  /// **Business Logic (The "Why"):**
  /// ใช้มาตรฐาน GATT Battery Service
  /// - `Service UUID`: `180f` 
  /// - `Characteristic UUID`: `2a19`
  /// เมื่ออ่านค่า Uint8List ตัวแรก (response[0]) ออกมา จะได้เปอร์เซ็นต์แบตจริงๆ 0-100% ทันที
  /// และแอบยิง `connectedTags.refresh()` เพื่ออัปเดตรูปไอคอนแบตเตอรี่บนหน้า UI ด้วย
  Future<void> _readBatteryLevel(String deviceId) async {
    final ble = FlutterReactiveBle();
    // Battery Service UUID: 180f, Level Characteristic UUID: 2a19
    final characteristic = QualifiedCharacteristic(
      serviceId: Uuid.parse("180f"),
      characteristicId: Uuid.parse("2a19"),
      deviceId: deviceId,
    );

    try {
      final response = await ble.readCharacteristic(characteristic);
      if (response.isNotEmpty) {
        final batteryLevel = response[0];
        debugPrint(
          "[BLE Battery] Real battery level for $deviceId: $batteryLevel%",
        );

        // Update the tag in the connected list
        final index = connectedTags.indexWhere(
          (tag) => tag.macAddress == deviceId,
        );
        if (index != -1) {
          final updatedTag = connectedTags[index];
          updatedTag.batteryPercentage = batteryLevel;
          connectedTags[index] = updatedTag; // Trigger GetX update
          connectedTags.refresh();
        }
      } else {
        debugPrint(
          "[BLE Battery] No battery level data received for $deviceId",
        );
      }
    } catch (e) {
      debugPrint(
        "[BLE Battery] Could not read battery level for $deviceId: $e",
      );
      // Some devices might not support standard battery service or require further steps
    }
  }

  void removeTag(String id) {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    Get.dialog(
      ConfirmDeleteDialog(
        onConfirm: () {
          registeredTags.removeWhere((tag) => tag.id == id);
          connectedTags.removeWhere((tag) => tag.id == id);
          // _saveTags();
          Get.snackbar('Removed', 'Tag has been removed successfully.');
          Get.back();
        },
        onCancel: () => Get.back(),
      ),
    );
  }

  @override
  void onClose() {
    pulseCtrl.dispose();
    macAddressController.dispose();
    _scanSubscription?.cancel();
    for (var sub in _connectionSubscriptions.values) {
      sub.cancel();
    }
    super.onClose();
  }
}
