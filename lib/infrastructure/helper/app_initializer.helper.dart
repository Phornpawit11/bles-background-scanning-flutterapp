import 'package:bearcon_card_app/config.dart';
import 'package:bearcon_card_app/infrastructure/service/background_ble_service.dart';
import 'package:bearcon_card_app/infrastructure/service/logger_service.dart';
import 'package:bearcon_card_app/infrastructure/theme/theme.controller.dart';
import 'package:bearcon_card_app/presentation/controllers/scan_mode.controller.dart';
import 'package:bearcon_card_app/presentation/loading/controllers/loading.controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:bearcon_card_app/presentation/controllers/language.controller.dart';

/// Utility class for initializing app components
class AppInitializer {
  /// Initializes all app components
  static Future<void> initialize({required String env}) async {
    // Initialize date formatting for Thai locale
    await initializeDateFormatting('th', null);
    // Initialize app configuration
    await ConfigEnvironments.environments(env: env);
    // Load environment variables
    await dotenv.load(fileName: ".env");
    // 1. ลงทะเบียน Global Service

    await initializeBackgroundService();

    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // runApp(...)
    Get.put(LanguageController()); // จัดการภาษาก่อนธีมและอย่างอื่น
    Get.put(ThemeController()); // ต้องโหลดธีมให้พร้อมก่อนแอปทำงาน
    Get.put(LoadingController()); // เริ่มตั้งแต่ start app
    Get.put(LoggerService());
  }
}
