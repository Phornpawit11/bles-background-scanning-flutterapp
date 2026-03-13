import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// ป้ายกำกับหมวดหมู่ (Section Label) 
class BeaconSectionLabel extends StatelessWidget {
  const BeaconSectionLabel({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Text(
          'bles_cards'.tr,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
        ),
      ),
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบการแสดงผล BeaconSectionLabel
@widgetbook.UseCase(
  name: 'Default',
  type: BeaconSectionLabel,
  path: '[Home]/SectionLabel',
)
Widget beaconSectionLabelUseCase(BuildContext context) {
  return const CustomScrollView(
    slivers: [
      BeaconSectionLabel(),
    ],
  );
}
