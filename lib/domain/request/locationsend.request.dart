import 'package:json_annotation/json_annotation.dart';

part 'locationsend.request.g.dart';

@JsonSerializable()
class LocationSendRequest {
  @JsonKey(name: "imei")
  final String imei;
  @JsonKey(name: "lat")
  final double lat;
  @JsonKey(name: "lng")
  final double lng;
  @JsonKey(name: "speed")
  final double speed;
  @JsonKey(name: "direction")
  final int direction;
  @JsonKey(name: "gps_time")
  final String gpsTime;
  @JsonKey(name: "batteryPowerVal")
  final double batteryPowerVal;

  LocationSendRequest({
    required this.imei,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.direction,
    required this.gpsTime,
    required this.batteryPowerVal,
  });

  factory LocationSendRequest.fromJson(Map<String, dynamic> json) =>
      _$LocationSendRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LocationSendRequestToJson(this);
}
