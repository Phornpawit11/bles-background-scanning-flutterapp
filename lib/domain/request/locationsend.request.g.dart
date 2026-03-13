// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locationsend.request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationSendRequest _$LocationSendRequestFromJson(Map<String, dynamic> json) =>
    LocationSendRequest(
      imei: json['imei'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speed: (json['speed'] as num).toDouble(),
      direction: (json['direction'] as num).toInt(),
      gpsTime: json['gps_time'] as String,
      batteryPowerVal: (json['batteryPowerVal'] as num).toDouble(),
    );

Map<String, dynamic> _$LocationSendRequestToJson(
        LocationSendRequest instance) =>
    <String, dynamic>{
      'imei': instance.imei,
      'lat': instance.lat,
      'lng': instance.lng,
      'speed': instance.speed,
      'direction': instance.direction,
      'gps_time': instance.gpsTime,
      'batteryPowerVal': instance.batteryPowerVal,
    };
