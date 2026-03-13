import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// ไดอะล็อกยืนยันการลบ Tag
class ConfirmDeleteDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmDeleteDialog({
    super.key,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: Icon(
        Icons.delete_forever_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text('delete_tag'.tr),
      content: Text(
        'delete_tag_prompt'.tr,
        textAlign: TextAlign.center,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        OutlinedButton(
          onPressed: onCancel,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('cancel'.tr),
        ),
        FilledButton.tonal(
          onPressed: onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text('delete'.tr),
        ),
      ],
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบไดอะล็อกยืนยันการลบ
@widgetbook.UseCase(
  name: 'Default',
  type: ConfirmDeleteDialog,
  path: '[Home]/ConfirmDeleteDialog',
)
Widget confirmDeleteDialogUseCase(BuildContext context) {
  return ConfirmDeleteDialog(
    onConfirm: () {},
    onCancel: () {},
  );
}
