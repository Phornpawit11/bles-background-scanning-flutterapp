import 'dart:async';
import 'dart:ui';
import 'package:bearcon_card_app/utils/bgservice.key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../config.dart';
import '../../presentation/controllers/background_ble.controller.dart';
import 'logger_service.dart';

/// ฟังก์ชันเริ่มต้น (Initialization) สำหรับเตรียมความพร้อมของ Background Service
/// 
/// **หน้าที่หลัก (Responsibilities):**
/// - สร้าง Notification Channel (บน Android) เพื่อให้ OS อนุญาตให้รัน Background ได้ (Foreground Service)
/// - ผูกคำสั่งตั้งต้นต่างๆ เช่น เมื่อเปิดเครื่องให้ทำงานเลยไหม (autoStartOnBoot), หน้าตา Notification ฯลฯ
/// 
/// **Business Logic (The "Why"):**
/// การสร้าง Background Service ใน Android/iOS ยุคใหม่ถูกบีบให้เข้มงวดมาก 
/// เราต้องบังคับใช้ `isForegroundMode: true` คู่กับ Notification เสมอ 
/// เพื่อให้ผู้ใช้รู้ตัวตนว่ามีการทำงานเบื้องหลัง ไม่เช่นนั้นระบบปฏิบัติการจะฆ่าแอปทิ้ง (Kill Process) ทันที
Future<void> initializeBackgroundService() async {
  debugPrint("[BLE Service] Initializing background service...");

  final logger = Get.put(LoggerService());
  await logger.addLog("Initializing background service...", type: 'INFO');

  // Create Notification Channel for Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    BGService.bgChannelId,
    BGService.bgChannelName,
    description: 'Running BLE and Location in background',
    importance: Importance.max,
  );

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      autoStartOnBoot: true,
      notificationChannelId: BGService.bgChannelId,
      initialNotificationTitle: 'Bearcon App Active',
      initialNotificationContent: 'Scanning for tags in background...',
      foregroundServiceNotificationId: BGService.foregroundNotificationId,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async => true;

/// จุดศูนย์กลาง (Entry Point) เริ่มรันลอจิกทั้งหมดเมื่อ Isolate พื้นหลังทำงาน
/// 
/// **ข้อควรระวัง (CRITICAL):**
/// โค้ดในบล็อก `onStart` นี้จะวิ่งอยู่บน **"Isolate ตัวใหม่"** ซึ่งแยกขาดกับหน้าจอ UI หลิักเด็ดขาด
/// หมายความว่าตัวแปร Memory, GetX Controllers เดิมๆ จะถูกรีเซ็ตใหม่ทั้งหมด
/// เราจึงต้องประกาศ `Get.put(...)` ซ้ำอีกรอบเพื่อสร้าง Instance สำหรับใช้งานดักฟังอยู่ข้างหลัง
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // 1. Load saved environment to sync with main isolate
  await ConfigEnvironments.loadSavedEnvironment();

  // Initialize essential services inside the isolate
  final logger = Get.put(LoggerService());
  logger.setServiceInstance(service);
  logger.addLog("Background service started.", type: 'INFO');

  // Initialize the logic controller
  final controller = Get.put(BackgroundBleController());

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((_) {
      logger.addLog("Switched to Foreground", type: 'INFO');
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((_) {
      logger.addLog("Switched to Background", type: 'INFO');
      service.setAsBackgroundService();
    });

    service.on('updateSubtext').listen((event) {
      if (event != null && event['subtext'] != null) {
        service.setForegroundNotificationInfo(
          title: 'Bearcon App Active',
          content: event['subtext'],
        );
      }
    });
  }

  service.on('stopService').listen((_) {
    logger.addLog("Stopping service...", type: 'WARNING');
    controller.stop();
    service.stopSelf();
  });

  // Start the intelligent adaptive scanning loop
  await controller.startAdaptiveScanning();
}
