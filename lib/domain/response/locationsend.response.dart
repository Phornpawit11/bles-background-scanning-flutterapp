import 'package:json_annotation/json_annotation.dart';

part 'locationsend.response.g.dart';

@JsonSerializable()
class LocationSendResponse {
  @JsonKey(name: "imei")
  final String imei;
  @JsonKey(name: "status")
  final String status;
  @JsonKey(name: "stored")
  final Stored stored;

  LocationSendResponse({
    required this.imei,
    required this.status,
    required this.stored,
  });

  factory LocationSendResponse.fromJson(Map<String, dynamic> json) =>
      _$LocationSendResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LocationSendResponseToJson(this);
}

@JsonSerializable()
class Stored {
  @JsonKey(name: "postgres")
  final bool postgres;
  @JsonKey(name: "redis")
  final bool redis;

  Stored({required this.postgres, required this.redis});

  factory Stored.fromJson(Map<String, dynamic> json) => _$StoredFromJson(json);

  Map<String, dynamic> toJson() => _$StoredToJson(this);
}
