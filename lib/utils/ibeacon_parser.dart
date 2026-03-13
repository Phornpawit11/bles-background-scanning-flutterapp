/// A robust Dart class to parse iBeacon manufacturer data.
/// Specifically crafted for the standard iBeacon payload structure.
class IBeaconData {
  final String uuid;
  final int major;
  final int minor;
  final int txPower;

  IBeaconData({
    required this.uuid,
    required this.major,
    required this.minor,
    required this.txPower,
  });

  /// Parses the [manufacturerData] from a Bluetooth LE packet.
  /// Returns an [IBeaconData] object if valid, or `null` if the data is too short.
  static IBeaconData? parse(List<int> manufacturerData) {
    // 1. Safety Check: The manufacturer data for iBeacon must be at least 25 bytes.
    if (manufacturerData.length < 25) {
      return IBeaconData(
        uuid: "",
        major: 0,
        minor: 0,
        txPower: 0,
      );
    }

    // 2. Extract UUID (Bytes 4-19)
    // Slicing 16 bytes and formatting them as standard uppercase UUID.
    final uuidBytes = manufacturerData.sublist(4, 20);
    final uuid = _formatUuid(uuidBytes);

    // 4. Extract Major & Minor (Bytes 20-21, 22-23)
    // Combining 2 bytes using bitwise operations (iBeacon uses Big-Endian).
    final int major = (manufacturerData[20] << 8) | manufacturerData[21];
    final int minor = (manufacturerData[22] << 8) | manufacturerData[23];

    // 3. Extract Tx Power (Byte 24)
    // Ensure we correctly interpret it as a signed 8-bit integer (e.g., -59 dBm).
    final int txPower = manufacturerData[24].toSigned(8);

    return IBeaconData(
      uuid: uuid,
      major: major,
      minor: minor,
      txPower: txPower,
    );
  }

  /// Helper function to convert 16 bytes into an uppercase UUID string.
  /// Target Format: XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
  static String _formatUuid(List<int> bytes) {
    final hexString = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join('');

    return '${hexString.substring(0, 8)}-'
        '${hexString.substring(8, 12)}-'
        '${hexString.substring(12, 16)}-'
        '${hexString.substring(16, 20)}-'
        '${hexString.substring(20, 32)}';
  }

  /// Converts the parsed data into a Map representation if needed.
  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'major': major,
      'minor': minor,
      'txPower': txPower,
    };
  }

  @override
  String toString() {
    return 'IBeaconData(uuid: $uuid, major: $major, minor: $minor, txPower: $txPower dBm)';
  }
}
