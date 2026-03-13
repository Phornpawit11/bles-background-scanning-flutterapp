import 'package:get/get.dart';

import '../../../../presentation/log/controllers/log.controller.dart';

class LogControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LogController>(
      () => LogController(),
    );
  }
}
