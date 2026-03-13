// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locationsend.response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationSendResponse _$LocationSendResponseFromJson(
        Map<String, dynamic> json) =>
    LocationSendResponse(
      imei: json['imei'] as String,
      status: json['status'] as String,
      stored: Stored.fromJson(json['stored'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LocationSendResponseToJson(
        LocationSendResponse instance) =>
    <String, dynamic>{
      'imei': instance.imei,
      'status': instance.status,
      'stored': instance.stored,
    };

Stored _$StoredFromJson(Map<String, dynamic> json) => Stored(
      postgres: json['postgres'] as bool,
      redis: json['redis'] as bool,
    );

Map<String, dynamic> _$StoredToJson(Stored instance) => <String, dynamic>{
      'postgres': instance.postgres,
      'redis': instance.redis,
    };
