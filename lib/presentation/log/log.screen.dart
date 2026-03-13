import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/log.controller.dart';
import '../widgets/dumb_widgets/log_item.dart';
import '../widgets/dumb_widgets/log_empty_state.dart';

class LogScreen extends GetView<LogController> {
  const LogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          'Background Logs',
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: cs.onSurface),
            onPressed: controller.refreshLogs,
            tooltip: 'Refresh',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: cs.onSurface),
              onPressed: () {
                Get.defaultDialog(
                  title: 'Clear Logs',
                  middleText: 'Are you sure you want to clear all logs?',
                  textConfirm: 'Clear',
                  textCancel: 'Cancel',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.redAccent,
                  onConfirm: () {
                    controller.clearLogs();
                    Get.back();
                  },
                );
              },
              tooltip: 'Clear Logs',
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.log.logs.isEmpty) {
          return const LogEmptyState();
        }

        final logs = controller.log.logs.toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            return LogItem(
              timestamp: log.timestamp,
              message: log.message,
              type: log.type,
              accentColor: _logColor(log.type),
            );
          },
        );
      }),
    );
  }

  Color _logColor(String type) {
    switch (type.toUpperCase()) {
      case 'SUCCESS':
        return const Color(0xFF4CAF50);
      case 'WARNING':
        return const Color(0xFFFF9800);
      case 'ERROR':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF3F51B5);
    }
  }
}
