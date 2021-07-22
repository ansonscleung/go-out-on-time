import 'package:flutter/material.dart';

import 'common.dart';

class StopList {
  final String type;
  final String version;
  final String generatedTimestamp;
  final List<Stop> data;

  StopList(
      {@required this.type,
        @required this.version,
        @required this.generatedTimestamp,
        this.data});

  factory StopList.fromJson(Map<String, dynamic> json, String operator)  {
    return StopList(
        type: json['type'],
        version: json['version'],
        generatedTimestamp: json['generated_timestamp'],
        data: (json['data'] as List)
            ?.map((stop) => Stop.fromStopList(stop))
            ?.toList());
  }

}class Stop {
  final String stop;
  final IntlString name;
  final double lat;
  final double long;
  final String dataTimestamp;

  Stop(
      {@required this.stop,
      @required this.name,
      @required this.lat,
      @required this.long,
      @required this.dataTimestamp});

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
        stop: json['data']['stop'].toString(),
        name: new IntlString(
          en: json['data']['name_en'],
          tc: json['data']['name_tc'],
          sc: json['data']['name_sc'],
        ),
        lat: double.parse(json['data']['lat'].toString()),
        long: double.parse(json['data']['long'].toString()),
        dataTimestamp: json['data']['data_timestamp']);
  }

  factory Stop.fromStopList(Map<String, dynamic> json) {
    return Stop(
        stop: json['stop'].toString(),
        name: new IntlString(
          en: json['name_en'],
          tc: json['name_tc'],
          sc: json['name_sc'],
        ),
        lat: double.parse(json['lat'].toString()),
        long: double.parse(json['long'].toString()),
        dataTimestamp: json['data_timestamp']);
  }
}
