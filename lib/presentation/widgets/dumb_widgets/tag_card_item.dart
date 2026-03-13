import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:bearcon_card_app/domain/models/tag_card.dart';

/// การ์ดแสดงผลข้อมูล Tag (Beacon) แต่ละใบ
class TagCardItem extends StatefulWidget {
  final TagCard tag;
  final bool isConnected;
  final DeviceConnectionState status;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const TagCardItem({
    super.key,
    required this.tag,
    this.isConnected = false,
    this.status = DeviceConnectionState.disconnected,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  State<TagCardItem> createState() => _TagCardItemState();
}

class _TagCardItemState extends State<TagCardItem> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.97);
  void _onTapUp(TapUpDetails _) => setState(() => _scale = 1.0);
  void _onTapCancel() => setState(() => _scale = 1.0);

  Color get _statusDotColor {
    switch (widget.status) {
      case DeviceConnectionState.connected:
        return const Color(0xFF4CAF50);
      case DeviceConnectionState.connecting:
      case DeviceConnectionState.disconnecting:
        return const Color(0xFFFF9800);
      case DeviceConnectionState.disconnected:
        return const Color(0xFFBDBDBD);
    }
  }

  String get _statusLabel {
    switch (widget.status) {
      case DeviceConnectionState.connected:
        return 'connected'.tr;
      case DeviceConnectionState.connecting:
        return 'connecting'.tr;
      case DeviceConnectionState.disconnecting:
        return 'disconnecting'.tr;
      case DeviceConnectionState.disconnected:
        return widget.isConnected ? 'ready'.tr : 'available'.tr;
    }
  }

  Color get _batteryColor {
    final pct = widget.tag.batteryPercentage;
    if (pct >= 70) return const Color(0xFF4CAF50);
    if (pct >= 30) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  IconData get _batteryIcon {
    final pct = widget.tag.batteryPercentage;
    if (pct >= 70) return Icons.battery_full_rounded;
    if (pct >= 30) return Icons.battery_4_bar_rounded;
    return Icons.battery_1_bar_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        widget.tag.name,
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusBadge(color: _statusDotColor, label: _statusLabel),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.tag.macAddress,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 16),
                Divider(
                    height: 1, color: cs.outlineVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _BatteryBadge(
                      icon: _batteryIcon,
                      color: _batteryColor,
                      percentage: widget.tag.batteryPercentage,
                    ),
                    const Spacer(),
                    if (widget.status == DeviceConnectionState.connecting)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: widget.isConnected
                            ? widget.onDisconnect
                            : widget.onConnect,
                        child: Text(
                          widget.isConnected ? 'disconnect'.tr : 'connect'.tr,
                          style: tt.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: widget.isConnected ? cs.error : cs.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _StatusBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
        ),
      ],
    );
  }
}

class _BatteryBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int percentage;

  const _BatteryBadge({
    required this.icon,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            '$percentage%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบการแสดงผล Tag Card การ์ดแต่ละใบ
@widgetbook.UseCase(
  name: 'Default',
  type: TagCardItem,
  path: '[Home]/TagCardItem',
)
Widget tagCardItemUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        TagCardItem(
          tag: TagCard(
            id: '1',
            name: 'Sample Beacon',
            macAddress: 'AA:BB:CC:DD:EE:FF',
            batteryPercentage: 85,
          ),
          isConnected: false,
          status: DeviceConnectionState.disconnected,
          onConnect: () {},
          onDisconnect: () {},
        ),
      ],
    ),
  );
}
