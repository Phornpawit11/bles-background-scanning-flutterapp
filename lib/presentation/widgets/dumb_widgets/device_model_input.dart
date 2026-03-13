import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// ช่องกรอกใส่ชื่อรุ่นอุปกรณ์ใหม่
class DeviceModelInput extends StatelessWidget {
  final TextEditingController textController;
  final VoidCallback onAdd;

  const DeviceModelInput({
    super.key,
    required this.textController,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: textController,
              style: Get.textTheme.bodyLarge?.copyWith(
                color: cs.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'add_device_model_hint'.tr,
                hintStyle: Get.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cs.surface,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'add'.tr,
            style: Get.textTheme.titleMedium?.copyWith(
              color: cs.onPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบช่องกรอกข้อมูล
@widgetbook.UseCase(
  name: 'Default',
  type: DeviceModelInput,
  path: '[Settings]/DeviceModelInput',
)
Widget deviceModelInputUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: DeviceModelInput(
      textController: TextEditingController(
        text: context.knobs.string(label: 'Initial Text', initialValue: 'PB'),
      ),
      onAdd: () {},
    ),
  );
}
