import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// ส่วนสำหรับเปิด/ปิด Background Scanning
class BackgroundServiceToggle extends StatelessWidget {
  final bool isRunning;
  final bool isToggling;
  final Function(bool) onChanged;

  const BackgroundServiceToggle({
    super.key,
    required this.isRunning,
    required this.isToggling,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isRunning
                      ? const Color(0xFF4CAF50)
                      : cs.onSurface.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'bg_service'.tr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isRunning ? 'bg_active_scanning'.tr : 'bg_inactive'.tr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          if (isToggling)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            )
          else
            Switch(
              value: isRunning,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบสวิตช์เปิด/ปิดบริการพื้นหลัง
@widgetbook.UseCase(
  name: 'Default',
  type: BackgroundServiceToggle,
  path: '[Home]/BackgroundServiceToggle',
)
Widget backgroundServiceToggleUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: BackgroundServiceToggle(
      isRunning: context.knobs.boolean(label: 'Is Running', initialValue: false),
      isToggling: context.knobs.boolean(label: 'Is Toggling', initialValue: false),
      onChanged: (val) {},
    ),
  );
}
