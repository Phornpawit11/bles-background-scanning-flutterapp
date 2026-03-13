import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// วิดเจ็ตข้อความ "กำลังค้นหา..." พร้อมจุดกระพริบ (Pulsing Indicator)
/// 
/// **หน้าที่หลัก:** 
/// แสดงผลสถานะกำลังค้นหา โดยรับค่า Animation ความทึบแสงมาจากภายนอก
class PulsingSearchTitle extends StatelessWidget {
  final Animation<double> opacityAnimation;

  const PulsingSearchTitle({
    super.key,
    required this.opacityAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: opacityAnimation,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'searching'.tr,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: primary,
              ),
        ),
      ],
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบการแสดงผล PulsingSearchTitle
@widgetbook.UseCase(
  name: 'Default',
  type: PulsingSearchTitle,
  path: '[Home]/PulsingTitle',
)
Widget pulsingSearchTitleUseCase(BuildContext context) {
  return PulsingSearchTitle(
    opacityAnimation: AlwaysStoppedAnimation(
      context.knobs.double.slider(
        label: 'Opacity',
        initialValue: 1.0,
        min: 0.0,
        max: 1.0,
      ),
    ),
  );
}
