import 'dart:async';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';

/// ตัวควบคุม (Controller) สำหรับรับส่งข้อมูลสถานะการสแกนแบบอัจฉริยะ (Adaptive Scan Mode)
/// 
/// **หน้าที่หลัก (Responsibilities):**
/// ทำหน้าที่เป็น "สะพานเชื่อม" ระหว่าง Background Service (Isolate ที่รันอยู่เบื้องหลัง) 
/// กับ Foreground UI (หน้าจอหลักของแอป) เพื่อให้หน้าจอสามารถแสดงผลได้ว่าตอนนี้ระบบกำลังอยู่ในโหมดใด (HOT, WARM, COLD)
///
/// **Business Logic (The "Why"):**
/// เนื่องจาก Background Service รันแยก Thread (Isolate) กันกับ UI หลัก ทำให้ไม่สามารถแชร์ตัวแปรตรงๆ ได้
/// คลาสนี้จึงใช้ Event Listener ของ `FlutterBackgroundService` เพื่อดักจับ Event `updateMode` 
/// ที่ส่งมาจาก `BackgroundBleController` เบื้องหลัง และนำมาอัปเดตแบบ Reactive (`RxString`) ให้หน้าจอเปลี่ยนตามทันที
class ScanModeController extends GetxController {
  /// เก็บสถานะโหมดปัจจุบัน (HOT, WARM, COLD) เพื่อนำไปแสดงผลบน UI (เช่น สร้าง Animation หรือเปลี่ยนสี)
  final RxString currentMode = 'COLD'.obs;
  StreamSubscription? _modeSubscription;

  @override
  void onInit() {
    super.onInit();
    _listenToServiceMode();
  }

  /// ดักจับการเปลี่ยนแปลง Mode จาก Background Isolate
  /// 
  /// **วิธีการทำงาน:**
  /// ฟัง Event ชื่อ `updateMode` ที่ถูก Broadcast ออกมาจาก Service 
  /// หากมีข้อมูลส่งมา จะทำการแคสต์ (Cast) เป็น String และยัดลง [currentMode] ทันที
  void _listenToServiceMode() {
    _modeSubscription = FlutterBackgroundService().on('updateMode').listen((event) {
      if (event != null && event['mode'] != null) {
        currentMode.value = event['mode'] as String;
      }
    });
  }

  @override
  void onClose() {
    _modeSubscription?.cancel();
    super.onClose();
  }
}
