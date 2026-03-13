import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// วิดเจ็ตแสดงผลเมื่อไม่มีข้อมูล Log
class LogEmptyState extends StatelessWidget {
  const LogEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 52,
            color: cs.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'no_logs_yet'.tr,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบหน้าว่างของ Log
@widgetbook.UseCase(
  name: 'Default',
  type: LogEmptyState,
  path: '[Logs]/LogEmptyState',
)
Widget logEmptyStateUseCase(BuildContext context) {
  return const LogEmptyState();
}
