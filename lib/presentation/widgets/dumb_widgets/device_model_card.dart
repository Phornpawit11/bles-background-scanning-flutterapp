import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// การ์ดรายชื่อโมเดลอุปกรณ์
class DeviceModelCard extends StatelessWidget {
  final String modelName;
  final VoidCallback onRemove;

  const DeviceModelCard({
    super.key,
    required this.modelName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          modelName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
        ),
        leading: Icon(
          Icons.memory_rounded,
          color: cs.primary,
        ),
        trailing: IconButton(
          style: IconButton.styleFrom(
            backgroundColor: cs.error.withValues(alpha: 0.1),
          ),
          icon: Icon(
            Icons.delete_outline_rounded,
            color: cs.error,
          ),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบการ์ดรายการโมเดล
@widgetbook.UseCase(
  name: 'Default',
  type: DeviceModelCard,
  path: '[Settings]/DeviceModelCard',
)
Widget deviceModelCardUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: DeviceModelCard(
      modelName: context.knobs.string(label: 'Model Name', initialValue: 'PB713'),
      onRemove: () {},
    ),
  );
}
