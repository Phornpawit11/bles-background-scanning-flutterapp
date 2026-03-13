import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:get/get.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:bearcon_card_app/domain/models/tag_card.dart';
import 'tag_card_item.dart';

/// รายการ Tag ทั้งหมดที่เชื่อมต่อแล้วและที่ยังไม่ได้เชื่อมต่อ
class TagList extends StatelessWidget {
  final List<TagCard> connectedTags;
  final List<TagCard> registeredTags;
  final Map<String, DeviceConnectionState> deviceStates;
  final Function(String mac) onConnect;
  final Function(String mac) onDisconnect;

  const TagList({
    super.key,
    required this.connectedTags,
    required this.registeredTags,
    required this.deviceStates,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // ── Empty State ──────────────────────────────────────────────────
    if (connectedTags.isEmpty && registeredTags.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bluetooth_searching_rounded,
                size: 52,
                color: cs.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 16),
              Text(
                'no_beacons_yet'.tr,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'search_to_add_beacon'.tr,
                textAlign: TextAlign.center,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Build flat item list for SliverList ──────────────────────────
    final List<Widget> items = [];

    if (connectedTags.isNotEmpty) {
      items.add(_SectionLabel(label: 'connected'.tr, count: connectedTags.length));
      items.add(const SizedBox(height: 10));
      for (final tag in connectedTags) {
        items.add(TagCardItem(
          tag: tag,
          isConnected: true,
          status: deviceStates[tag.macAddress] ?? DeviceConnectionState.connected,
          onConnect: () {},
          onDisconnect: () => onDisconnect(tag.macAddress),
        ));
      }
      items.add(const SizedBox(height: 16));
    }

    if (registeredTags.isNotEmpty) {
      items.add(_SectionLabel(label: 'available'.tr, count: registeredTags.length));
      items.add(const SizedBox(height: 10));
      for (final tag in registeredTags) {
        items.add(TagCardItem(
          tag: tag,
          isConnected: false,
          status: deviceStates[tag.macAddress] ?? DeviceConnectionState.disconnected,
          onConnect: () => onConnect(tag.macAddress),
          onDisconnect: () {},
        ));
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => items[index],
        childCount: items.length,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final int count;

  const _SectionLabel({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: Get.textTheme.titleSmall?.copyWith(
              color: cs.primary,
            ),
          ),
        ),
      ],
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบรายการ Tag ทั้งหมด
@widgetbook.UseCase(
  name: 'Default',
  type: TagList,
  path: '[Home]/TagList',
)
Widget tagListUseCase(BuildContext context) {
  return CustomScrollView(
    slivers: [
      TagList(
        connectedTags: [
          TagCard(id: '1', name: 'Beac-01', macAddress: 'AA:BB:CC:DD:EE:FF', batteryPercentage: 80),
        ],
        registeredTags: [
          TagCard(id: '2', name: 'Beac-02', macAddress: '11:22:33:44:55:66', batteryPercentage: 45),
        ],
        deviceStates: const {},
        onConnect: (m) {},
        onDisconnect: (m) {},
      ),
    ],
  );
}
