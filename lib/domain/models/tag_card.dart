/// โมเดลข้อมูล [TagCard] สำหรับเก็บรายละเอียดของ BLE Beacon แต่ละตัว
class TagCard {
  final String id;
  final String name;
  final String macAddress;
  int batteryPercentage;

  TagCard({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.batteryPercentage,
  });

  factory TagCard.fromJson(Map<String, dynamic> json) {
    return TagCard(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      macAddress: json['macAddress'] ?? '',
      batteryPercentage: json['batteryPercentage'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'macAddress': macAddress,
      'batteryPercentage': batteryPercentage,
    };
  }
}
