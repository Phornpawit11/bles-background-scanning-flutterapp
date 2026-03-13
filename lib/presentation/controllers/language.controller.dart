import 'dart:ui';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ตัวควบคุม (Controller) สำหรับเปลี่ยนและจดจำภาษาของแอปพลิเคชัน (Internationalization - i18n)
///
/// **หน้าที่หลัก (Responsibilities):**
/// - จัดการ Locale ตลอดทั่วทั้งแอปโดยผสานกับระบบของ `GetX` (`Get.updateLocale`)
/// - ดึงค่าภาษาเริ่มต้นจากตัวเครื่อง (Device Locale) ในกรณีที่เพิ่งโหลดแอปครั้งแรก
/// - บันทึกและอ่านการตั้งค่าภาษาจากฐานข้อมูลท้องถิ่น (`SharedPreferences`) เพื่อให้จำได้เมื่อเปิดแอปใหม่
///
/// **Business Logic (The "Why"):**
/// การใช้ GetX คู่กับ SharedPreferences ช่วยให้แอปเปลี่ยนภาษาได้แบบ Real-time โดยไม่ต้อง Restart แอป
/// และการมีคลาสแยกสำหรับจัดการภาษาโดยเฉพาะ (Single Responsibility) ช่วยให้โค้ดส่วน UI สะอาดขึ้นมาก
class LanguageController extends GetxController {
  /// ตัวช่วย (Getter) สำหรับเรียกใช้คลาสนี้จากที่ไหนก็ได้ในแอปแบบสั้นๆ (เช่น `LanguageController.to.changeLanguage(...)`)
  static LanguageController get to => Get.find();

  /// สถานะภาษาปัจจุบันของแอปพลิเคชัน ใช้ `Rx<Locale>` เพื่อให้ UI วาดใหม่ (Rebuild) อัตโนมัติเมื่อภาษาเปลี่ยน
  final Rx<Locale> currentLocale = Get.deviceLocale!.obs;

  static const _langCodeKey = 'languageCode';
  static const _countryCodeKey = 'countryCode';

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  /// โหลดภาษาที่ผู้ใช้เคยเลือกบันทึกไว้ขึ้นมา
  ///
  /// **Business Logic (The "Why"):**
  /// เมื่อแอปเปิดขึ้นมา ระบบจะพยายามค้นหาคีย์ภาษา (`languageCode`, `countryCode`) จาก Storage
  /// หากพบค่า ระบบจะเปลี่ยนภาษาแอปตามค่านั้นทันที แต่ถ้าหาไม่เจอ (เป็นผู้ใช้ใหม่)
  /// ระบบจะใช้ภาษาเริ่มต้นตามระบบปฏิบัติการ (Device Locale) หากอ่านค่าจากเครื่องไม่ได้อีก ก็จะบังคับเป็น `en_US` ดักไว้ขั้นสุดท้าย
  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_langCodeKey);
    final countryCode = prefs.getString(_countryCodeKey);

    if (langCode != null && countryCode != null) {
      final locale = Locale(langCode, countryCode);
      currentLocale.value = locale;
      Get.updateLocale(locale);
    } else {
      // Default to device locale if nothing is saved
      final deviceLocale = Get.deviceLocale ?? const Locale('en', 'US');
      currentLocale.value = deviceLocale;
      Get.updateLocale(deviceLocale);
    }
  }

  /// เปลี่ยนภาษาของแอปพร้อมกับบันทึกลงหน่วยความจำ
  ///
  /// **พารามิเตอร์ (Params):**
  /// - [languageCode]: รหัสภาษา (เช่น 'th' สำหรับภาษาไทย, 'en' สำหรับภาษาอังกฤษ)
  /// - [countryCode]: รหัสประเทศ (เช่น 'TH', 'US')
  ///
  /// **วิธีการทำงาน:**
  /// 1. นำ Parameter มาสร้างก้อน [Locale] ตัวใหม่
  /// 2. สั่งให้ GetX อัปเดตภาษาทั้งแอป (`Get.updateLocale`)
  /// 3. เปลี่ยนค่าในตัวแปร Reactive เผื่อให้ UI ที่ผูกไว้ขยับตาม
  /// 4. เซฟค่า Locale ใหม่ลง `SharedPreferences`
  /// 5. หากเรียกใช้คำสั่งนี้ผ่านหน้าต่าง Pop-up (Dialog) ให้สั่งปลด Pop-up ปิดลงไปด้วย
  Future<void> changeLanguage(String languageCode, String countryCode) async {
    final locale = Locale(languageCode, countryCode);

    // Update locale
    Get.updateLocale(locale);
    currentLocale.value = locale;

    // Save persistently
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langCodeKey, languageCode);
    await prefs.setString(_countryCodeKey, countryCode);

    // Close dialog
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}
