import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'device_model_card.dart';

/// วิดเจ็ตแสดงรายการโมเดลอุปกรณ์ที่อนุญาต
class DeviceModelList extends StatelessWidget {
  final List<String> models;
  final Function(String) onRemove;

  const DeviceModelList({
    super.key,
    required this.models,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return const SizedBox();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      itemCount: models.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final model = models[index];
        return DeviceModelCard(
          modelName: model,
          onRemove: () => onRemove(model),
        );
      },
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบรายการโมเดลอุปกรณ์
@widgetbook.UseCase(
  name: 'Default',
  type: DeviceModelList,
  path: '[Settings]/DeviceModelList',
)
Widget deviceModelListUseCase(BuildContext context) {
  return DeviceModelList(
    models: context.knobs.object.dropdown(
      label: 'Sample List',
      options: [
        ['PB713', 'PB712'],
        ['PB713'],
        [],
      ],
    ),
    onRemove: (m) {},
  );
}
