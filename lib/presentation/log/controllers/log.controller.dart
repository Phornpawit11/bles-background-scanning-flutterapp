import 'package:get/get.dart';
import '../../../infrastructure/service/logger_service.dart';

class LogController extends GetxController {
  final RxBool isLoading = true.obs;
  final LoggerService log = Get.find<LoggerService>();
  @override
  void onInit() {
    log.fetchLogs().whenComplete(() {
      isLoading.value = false;
    });
    super.onInit();
  }

  Future<void> fetchLogs() async {
    isLoading.value = true;
    try {
      await log.fetchLogs();
      // Ensure logs are sorted by latest time first
      log.logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> clearLogs() async {
    await Get.find<LoggerService>().clearLogs();
    log.clearLogs();
    Get.snackbar('Logs Cleared', 'All background logs have been removed.');
  }

  void refreshLogs() async {
    isLoading.value = true;
    await fetchLogs().whenComplete(() {
      isLoading.value = false;
    });
  }
}
