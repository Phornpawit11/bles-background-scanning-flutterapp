import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controllers/devicemodelsetting.controller.dart';
import '../widgets/dumb_widgets/warning_banner.dart';
import '../widgets/dumb_widgets/device_model_input.dart';
import '../widgets/dumb_widgets/device_model_list.dart';

class DevicemodelsettingScreen extends GetView<DevicemodelsettingController> {
  const DevicemodelsettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('manage_device_models'.tr),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const WarningBanner(),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: DeviceModelInput(
              textController: controller.modelInputController,
              onAdd: controller.addModel,
            ),
          ),
          Expanded(
            child: Obx(() => DeviceModelList(
                  models: controller.allowedModels.toList(),
                  onRemove: (model) => controller.removeModel(model),
                )),
          ),
        ],
      ),
    );
  }
}
