import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController with WidgetsBindingObserver {
  static ThemeController get to => Get.find();

  final RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    isDarkMode.value =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
  }

  @override
  void onReady() {
    super.onReady();
    Get.changeThemeMode(ThemeMode.system);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangePlatformBrightness() {
    isDarkMode.value =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
            Brightness.dark;
    Get.changeThemeMode(ThemeMode.system);
    super.didChangePlatformBrightness();
  }

  void toggleTheme(bool value) {
    isDarkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }
}
