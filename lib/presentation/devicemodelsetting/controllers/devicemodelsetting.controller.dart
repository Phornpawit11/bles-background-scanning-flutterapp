import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// คลาส [DevicemodelsettingController] เป็นตัวควบคุม (Controller) หลักสำหรับหน้าตั้งค่า "รุ่นอุปกรณ์ที่อนุญาต" (Allowed Device Models)
///
/// **หน้าที่หลัก (Responsibilities):**
/// จัดการรายชื่อคำนำหน้า (Prefix) หรือรุ่นของ BLE Beacon ที่แอปพลิเคชันอนุญาตให้สแกนและประมวลผล 
/// โดยจะประสานงานกับ `SharedPreferences` เพื่อบันทึกข้อมูลถาวร และจัดการสถานะของ Background Service 
/// ระหว่างที่มีการเปลี่ยนแปลงการตั้งค่า
///
/// **Business Logic (The "Why"):**
/// - ในการทำงานจริง มี BLE Device ลอยอยู่ในอากาศจำนวนมาก การตั้งค่ารหัสรุ่น (เช่น "PB713") 
///   จะช่วยฟิลเตอร์ข้อมูลขยะทิ้งตั้งแต่ระดับต้นหลอด (Isolate) ทำให้ประหยัดแบตเตอรี่และ CPU ของเครื่องดักฟังขุมหลังอย่างมาก
/// - เมื่อเข้ามาหน้านี้ ระบบจะทำการ "หยุด" Background Service ชั่วคราว เพื่อป้องกันการชนกันของการเขียน/อ่านข้อมูล
///   และป้องกันการส่งค่า Filter ที่ไม่สมบูรณ์ไปยัง Isolate ที่กำลังรันอยู่ ก่อนจะเปิดใหม่ตอนปิดหน้าจอ (onClose)
class DevicemodelsettingController extends GetxController {
  /// รายการรุ่นอุปกรณ์ หรือ คำนำหน้า (Prefix) ที่อนุญาตให้ระบบจับสัญญาณ (เช่น "PB713")
  /// 
  /// ใช้ `RxList` เพื่อให้ UI สามารถอัปเดตแบบเรียลไทม์ได้ทันทีที่มีการเพิ่มหรือลบ
  final RxList<String> allowedModels = <String>[].obs;

  /// ควบคุมช่องกรอกข้อความ (TextField) สำหรับการพิมพ์เพิ่มรุ่นอุปกรณ์ใหม่
  final TextEditingController modelInputController = TextEditingController();

  /// กุญแจ (Key) ที่ใช้สำหรับการจัดเก็บข้อมูลลงใน Local Storage (SharedPreferences)
  static const String _prefsKey = 'allowed_device_models';

  @override
  void onInit() {
    super.onInit();
    _loadAllowedModels();
    _stopBackgroundService();
  }

  /// โหลดรายชื่อรุ่นอุปกรณ์จาก Local Storage
  /// 
  /// **Business Logic (The "Why"):**
  /// หากเป็นผู้ใช้งานใหม่และยังไม่มีข้อมูลใน Storage ระบบจะตั้งค่าเริ่มต้นเป็น `['PB713']` 
  /// เพื่อให้แอปสามารถทำงานสแกน Beacon รุ่นมาตรฐานของระบบได้อย่างน้อย 1 รุ่นโดยที่ผู้ใช้ไม่ต้องตั้งค่าเอง
  Future<void> _loadAllowedModels() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModels = prefs.getStringList(_prefsKey);
    if (savedModels == null || savedModels.isEmpty) {
      allowedModels.assignAll(['PB713']);
    } else {
      allowedModels.assignAll(savedModels);
    }
  }

  /// บันทึกรายชื่อรุ่นอุปกรณ์ปัจจุบันลง Local Storage เพื่อให้จำค่าไว้ใช้ในครั้งถัดไป
  Future<void> _saveAllowedModels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, allowedModels.toList());
  }

  /// เพิ่มชื่อรุ่นอุปกรณ์ใหม่เข้าไประบบ
  /// 
  /// **วิธีการทำงาน:**
  /// 1. อ่านค่าจาก Input 
  /// 2. ลบช่องว่าง (trim) และแปลงเป็นตัวพิมพ์ใหญ่ (toUpperCase) เสมอ เพื่อลดปัญหา Case-Sensitive ตอนตรวจสอบกับ MAC Address/ชื่อบลูทูธ
  /// 3. เช็คว่ามีอยู่แล้วหรือไม่ ถ้ายังไม่มีให้เพิ่มลง `allowedModels` และเซฟลง DB
  /// 4. เคลียร์ค่าในช่องพิมพ์และสั่งปิดคีย์บอร์ด
  void addModel() {
    final newModel = modelInputController.text.trim().toUpperCase();
    if (newModel.isNotEmpty && !allowedModels.contains(newModel)) {
      allowedModels.add(newModel);
      _saveAllowedModels();
      modelInputController.clear();
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  /// ลบรุ่นอุปกรณ์ออกจากระบบ
  /// 
  /// **พารามิเตอร์ [model]:** ชื่อข้อความรุ่น/Prefix ที่ต้องการจะลบออก
  /// 
  /// **Business Logic (The "Why"):**
  /// มีการทำเงื่อนไขเช็คว่า `allowedModels.length > 1` เพื่อเป็นการบังคับว่า **ต้องมีรุ่นอุปกรณ์อย่างน้อย 1 รุ่นเสมอ**
  /// หากปล่อยให้ผู้ใช้ลบจนว่างเปล่า Background Service จะสแกนไม่เจออะไรเลย และแอปจะหยุดทำงานโดยสมบูรณ์
  /// หากมีแค่ 1 อัน จะขึ้น Snackbar แจ้งเตือนผู้ใช้แทน
  void removeModel(String model) {
    if (allowedModels.length > 1 || !allowedModels.contains(model)) {
      allowedModels.remove(model);
      _saveAllowedModels();
    } else {
      Get.snackbar(
        'Cannot Remove',
        'At least one device model must be allowed.',
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  /// สั่งหยุดการทำงานของ Background Service (ดึงจาก Isolate ลงมา)
  /// 
  /// **Business Logic (The "Why"):**
  /// การเปิด/ปิด หรือแก้ไข Filter ในขณะที่ Isolate ทำงานอยู่รอบนอก (Background) 
  /// อาจทำให้ SharedPreferences ถูกอ่าน/เขียน ชนกัน จึงต้องสั่งหยุดเพื่อความปลอดภัยของข้อมูล
  void _stopBackgroundService() {
    // We invoke 'stopService' directly on the service exactly as requested
    FlutterBackgroundService().invoke('stopService');
  }

  /// ถูกเรียกเมื่อมีการยุบหน้าต่าง หรือทำลาย Controller ทิ้ง (ผู้ใช้กดออกหน้าตั้งค่า)
  /// 
  /// **Business Logic (The "Why"):**
  /// เมื่อการแก้ไขเสร็จสิ้น ระบบจะสั่งล้างข้อมูลใน Controller (`dispose()`) จากนั้น
  /// จะทำการสั่งเริ่ม `startService()` ใหม่ เพื่อให้ Background Service ตื่นขึ้นมา 
  /// โหลด SharedPreferences ก้อนใหม่ (ที่เพิ่งเซฟไป) เข้าสู่หน่วยความจำ
  @override
  void onClose() {
    modelInputController.dispose();
    // Restart background service naturally to pick up new prefs
    FlutterBackgroundService().startService();
    super.onClose();
  }
}
