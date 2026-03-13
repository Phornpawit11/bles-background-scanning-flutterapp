import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// ป้ายแสดงสถานะโหมดการสแกน (HOT, WARM, COLD)
class ScanModeBadge extends StatelessWidget {
  final String mode;

  const ScanModeBadge({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    Color badgeColor;
    Color textColor;
    String label;

    switch (mode.toUpperCase()) {
      case 'HOT':
        iconData = Icons.local_fire_department_rounded;
        badgeColor = Colors.red.withAlpha(25);
        textColor = Colors.red.shade700;
        label = 'hot'.tr;
        break;
      case 'WARM':
        iconData = Icons.directions_walk_rounded;
        badgeColor = Colors.orange.withAlpha(25);
        textColor = Colors.orange.shade800;
        label = 'warm'.tr;
        break;
      case 'COLD':
      default:
        iconData = Icons.ac_unit_rounded;
        badgeColor = Colors.blue.withAlpha(25);
        textColor = Colors.blue.shade700;
        label = 'cold'.tr;
        break;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              iconData,
              key: ValueKey<String>(mode),
              color: textColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              label,
              key: ValueKey<String>(mode),
              style: Get.textTheme.titleSmall?.copyWith(
                color: textColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบการแสดงผล Scan Mode Badge
@widgetbook.UseCase(
  name: 'Default',
  type: ScanModeBadge,
  path: '[Home]/ScanModeBadge',
)
Widget scanModeBadgeUseCase(BuildContext context) {
  return Center(
    child: ScanModeBadge(
      mode: context.knobs.list(
        label: 'Mode',
        options: ['HOT', 'WARM', 'COLD'],
        initialOption: 'HOT',
      ),
    ),
  );
}
