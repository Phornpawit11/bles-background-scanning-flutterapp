import 'package:get/get.dart';

import '../../../../presentation/loading/controllers/loading.controller.dart';

class LoadingControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoadingController>(
      () => LoadingController(),
    );
  }
}
