import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// แบนเนอร์แจ้งเตือนสีส้ม
class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Colors.orange.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'background_tracking_paused'.tr,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบการแสดงผล WarningBanner
@widgetbook.UseCase(
  name: 'Default',
  type: WarningBanner,
  path: '[Settings]/WarningBanner',
)
Widget warningBannerUseCase(BuildContext context) {
  return const WarningBanner();
}
