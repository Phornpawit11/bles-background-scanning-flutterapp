/// โมเดลข้อมูลสำหรับการบันทึก Log ในระบบ
class BackgroundLog {
  final DateTime timestamp;
  final String message;
  final String type; // 'INFO', 'SUCCESS', 'WARNING', 'ERROR'

  BackgroundLog({
    required this.timestamp,
    required this.message,
    this.type = 'INFO',
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'message': message,
    'type': type,
  };

  factory BackgroundLog.fromJson(Map<String, dynamic> json) {
    return BackgroundLog(
      timestamp: DateTime.parse(json['timestamp']),
      message: json['message'],
      type: json['type'] ?? 'INFO',
    );
  }
}
