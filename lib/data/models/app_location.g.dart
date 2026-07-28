// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppLocation _$AppLocationFromJson(Map<String, dynamic> json) => _AppLocation(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  cep: json['cep'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  raio: (json['raio'] as num?)?.toInt() ?? 10,
  precise: json['precise'] as bool? ?? false,
);

Map<String, dynamic> _$AppLocationToJson(_AppLocation instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'cep': instance.cep,
      'city': instance.city,
      'state': instance.state,
      'raio': instance.raio,
      'precise': instance.precise,
    };
