import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// วิดเจ็ตแสดงผลรายการ Log แต่ละรายการ
class LogItem extends StatelessWidget {
  final DateTime timestamp;
  final String message;
  final String type;
  final Color accentColor;

  const LogItem({
    super.key,
    required this.timestamp,
    required this.message,
    required this.type,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final timeStr = DateFormat('dd MMM  HH:mm:ss').format(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              type.toUpperCase(),
                              style: tt.bodyMedium?.copyWith(
                                letterSpacing: 0.8,
                                color: accentColor,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            timeStr,
                            style: tt.labelMedium?.copyWith(
                              color: cs.onSurface.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// **Widgetbook UseCase**: ทดสอบการแสดงผล Log Item
@widgetbook.UseCase(
  name: 'Default',
  type: LogItem,
  path: '[Logs]/LogItem',
)
Widget logItemUseCase(BuildContext context) {
  final type = context.knobs.list(
    label: 'Log Type',
    options: ['INFO', 'SUCCESS', 'WARNING', 'ERROR'],
  );

  Color color;
  switch (type) {
    case 'SUCCESS':
      color = const Color(0xFF4CAF50);
      break;
    case 'WARNING':
      color = const Color(0xFFFF9800);
      break;
    case 'ERROR':
      color = const Color(0xFFF44336);
      break;
    default:
      color = const Color(0xFF3F51B5);
  }

  return Padding(
    padding: const EdgeInsets.all(20.0),
    child: Column(
      children: [
        LogItem(
          timestamp: DateTime.now(),
          message: context.knobs.string(
              label: 'Message', initialValue: 'This is a sample log message'),
          type: type,
          accentColor: color,
        ),
      ],
    ),
  );
}
