import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// หน้าจอป้องกัน (Gate) เมื่อ Bluetooth ปิดอยู่หรือไม่ได้อนุญาต Permission
class BluetoothPermissionGate extends StatelessWidget {
  final String status;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  const BluetoothPermissionGate({
    super.key,
    required this.status,
    required this.onRetry,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'granted') return const SizedBox.shrink();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: switch (status) {
        'checking' => const _CheckingView(),
        'off' => _BlockedView(
            icon: Icons.bluetooth_disabled_rounded,
            title: 'bt_is_off'.tr,
            subtitle: 'bt_location_turn_on'.tr,
            buttonLabel: 'retry'.tr,
            onAction: onRetry,
          ),
        'denied' => _BlockedView(
            icon: Icons.lock_outline_rounded,
            title: 'permission_denied'.tr,
            subtitle: 'bt_location_required'.tr,
            buttonLabel: 'open_settings'.tr,
            onAction: onOpenSettings,
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _CheckingView extends StatelessWidget {
  const _CheckingView();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: cs.primary, strokeWidth: 2),
          const SizedBox(height: 20),
          Text(
            'checking_permissions'.tr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }
}

class _BlockedView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onAction;

  const _BlockedView({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: cs.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: tt.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบหน้าจอป้องกันสิทธิ์
@widgetbook.UseCase(
  name: 'States',
  type: BluetoothPermissionGate,
  path: '[Home]/BluetoothPermissionGate',
)
Widget bluetoothPermissionGateUseCase(BuildContext context) {
  return BluetoothPermissionGate(
    status: context.knobs.list(
      label: 'Status',
      options: ['checking', 'off', 'denied', 'granted'],
      initialOption: 'checking',
    ),
    onRetry: () {},
    onOpenSettings: () {},
  );
}
