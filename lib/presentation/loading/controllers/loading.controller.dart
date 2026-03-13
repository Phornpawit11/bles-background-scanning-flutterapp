// infrastructure/loading/controllers/loading.controller.dart
import 'package:get/get.dart';

class LoadingController extends GetxController {
  var isLoading = false.obs;
  var title = ''.obs;

  void showLoading([String? message]) async {
    title.value = message ?? '';
    isLoading.value = true;
    // Get.log('$message', isError: true);
  }

  void hideLoading() {
    isLoading.value = false;
    title.value = '';
    // Get.log('ปิดการงาน hideLoading', isError: true);
  }
}
