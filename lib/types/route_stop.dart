import 'package:flutter/material.dart';

import 'stop.dart';

class RouteStopList {
  final String type;
  final String version;
  final String generatedTimestamp;
  final List<RouteStop> data;

  RouteStopList(
      {@required this.type,
      @required this.version,
      @required this.generatedTimestamp,
      this.data});

  factory RouteStopList.fromJson(Map<String, dynamic> json,
      {bool isKMB = false}) {
    return RouteStopList(
        type: json['type'],
        version: json['version'],
        generatedTimestamp: json['generated_timestamp'],
        data: (json['data'] as List)
            ?.map((route) => RouteStop.fromJson(route, isKMB: isKMB))
            ?.toList());
  }
}

class RouteStop {
  final String co;
  final String route;
  final String direction;
  final String serviceType;
  final int seq;
  final String stop;
  Stop stopInfo;
  final String dataTimestamp;

  RouteStop(
      {@required this.co,
      @required this.route,
      @required this.direction,
      @required this.serviceType,
      @required this.seq,
      @required this.stop,
        this.stopInfo,
      @required this.dataTimestamp});

  factory RouteStop.fromJson(Map<String, dynamic> json, {bool isKMB = false}) {
    var directionString = json['dir'] != null ? json['dir'] : json["bound"];
    return RouteStop(
        co: isKMB ? "KMB/LWB" : json['co'],
        route: json['route'],
        direction: directionString == "I" ? "inbound" : "outbound",
        serviceType: json['service_type'],
        seq: int.parse(json['seq'].toString()),
        stop: json['stop'].toString(),
        dataTimestamp: json['data_timestamp']);
  }
}
