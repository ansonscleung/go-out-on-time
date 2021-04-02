import 'package:flutter/material.dart';

import 'common.dart';

class Stop {
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
}
