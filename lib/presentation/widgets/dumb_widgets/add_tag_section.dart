import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// ส่วนสำหรับค้นหา/เพิ่ม Tag ใหม่
class AddTagSection extends StatelessWidget {
  final TextEditingController textController;
  final bool isScanning;
  final Animation<double>? pulseAnimation;
  final VoidCallback onAction;

  const AddTagSection({
    super.key,
    required this.textController,
    required this.isScanning,
    this.pulseAnimation,
    required this.onAction,
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
                hintText: 'search_tag_hint'.tr,
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
          onPressed: onAction,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
            disabledBackgroundColor: cs.primary.withValues(alpha: 0.5),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: isScanning
              ? (pulseAnimation != null
                  ? FadeTransition(
                      opacity: pulseAnimation!,
                      child: Icon(
                        Icons.stop_rounded,
                        size: 22,
                        color: cs.onPrimary,
                      ),
                    )
                  : Icon(
                      Icons.stop_rounded,
                      size: 22,
                      color: cs.onPrimary,
                    ))
              : Icon(
                  Icons.radar_rounded,
                  size: 22,
                  color: cs.onPrimary,
                ),
        ),
      ],
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบส่วนการเพิ่ม Tag
@widgetbook.UseCase(
  name: 'Default',
  type: AddTagSection,
  path: '[Home]/AddTagSection',
)
Widget addTagSectionUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: AddTagSection(
      textController: TextEditingController(),
      isScanning: context.knobs.boolean(label: 'Is Scanning', initialValue: false),
      onAction: () {},
    ),
  );
}
