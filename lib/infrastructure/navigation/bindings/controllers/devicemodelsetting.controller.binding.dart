import 'package:get/get.dart';

import '../../../../presentation/devicemodelsetting/controllers/devicemodelsetting.controller.dart';

class DevicemodelsettingControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DevicemodelsettingController>(
      () => DevicemodelsettingController(),
    );
  }
}
