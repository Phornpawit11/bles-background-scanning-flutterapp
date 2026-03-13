import 'dart:convert';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'package:bearcon_card_app/domain/models/log_entry.dart';

class LoggerService extends GetxService {
  static const String _logKey = 'background_service_logs';
  static const int _maxLogs = 500; // Limit to prevent SharedPreferences bloat
  final RxList<BackgroundLog> logs = <BackgroundLog>[].obs;

  // Isolate communication handle
  ServiceInstance? _serviceInstance;
  ServiceInstance? get serviceInstance => _serviceInstance;

  /// Registers the service instance (called within the background isolate)
  void setServiceInstance(ServiceInstance service) {
    _serviceInstance = service;
  }

  @override
  void onInit() {
    fetchLogs();

    // Listen for log events (UI Side)
    // Only subscribe if we are in the main app (not isolate or if service is configured)
    FlutterBackgroundService().on('on_log_added').listen((event) {
      if (event != null && event['log'] != null) {
        final newLog = BackgroundLog.fromJson(event['log']);

        // Avoid duplicate if the same instance added it (though isolates are separate)
        // Prevent adding if timestamp/message matches the top log exactly
        if (logs.isEmpty || logs.first.timestamp != newLog.timestamp) {
          logs.insert(0, newLog);
          if (logs.length > _maxLogs) {
            logs.removeLast();
          }
        }
      }
    });

    super.onInit();
  }

  Future fetchLogs() async {
    logs.value = await getLogs();
  }

  Future<void> addLog(String message, {String type = 'INFO'}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> logsRaw = prefs.getStringList(_logKey) ?? [];

      final newLog = BackgroundLog(
        timestamp: DateTime.now(),
        message: message,
        type: type,
      );

      logsRaw.insert(0, jsonEncode(newLog.toJson())); // Add to top

      // Keep only _maxLogs
      if (logsRaw.length > _maxLogs) {
        logsRaw = logsRaw.sublist(0, _maxLogs);
      }

      logs.insert(0, newLog);
      if (logs.length > _maxLogs) {
        logs.removeLast();
      }

      // Notify UI if we are in the background isolate
      _serviceInstance?.invoke('on_log_added', {'log': newLog.toJson()});

      await prefs.setStringList(_logKey, logsRaw);
    } catch (e) {
      print("Failed to save log: $e");
    }
  }

  Future<List<BackgroundLog>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsRaw = prefs.getStringList(_logKey) ?? [];
      return logsRaw.map((e) => BackgroundLog.fromJson(jsonDecode(e))).toList();
    } catch (e) {
      print("Failed to retrieve logs: $e");
      return [];
    }
  }

  Future<void> clearLogs() async {
    final prefs = await SharedPreferences.getInstance();
    logs.value = [];
    await prefs.remove(_logKey);
  }
}
