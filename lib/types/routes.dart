import 'package:flutter/material.dart';
import 'package:go_out_on_time/types/common.dart';

class RouteList {
  final String type;
  final String version;
  final String generatedTimestamp;
  final List<BusRoute> data;

  RouteList(
      {@required this.type,
      @required this.version,
      @required this.generatedTimestamp,
      this.data});

  factory RouteList.fromJson(Map<String, dynamic> json, String operator)  {
    return RouteList(
        type: json['type'],
        version: json['version'],
        generatedTimestamp: json['generated_timestamp'],
        data: (json['data'] as List)
            ?.map((route) => BusRoute.fromJson(route, operator))
            ?.toList());
  }

  factory RouteList.fromBravo(Map<String, dynamic> json, List<dynamic> routes)  {
    return RouteList(
        type: json['type'],
        version: json['version'],
        generatedTimestamp: json['generated_timestamp'],
        data: routes);
  }
}

class BusRoute {
  final String co;
  final String route;
  final String direction;
  final String serviceType;
  final IntlString orig;
  final IntlString dest;
  final String dataTimestamp;

  BusRoute(
      {@required this.co,
      @required this.route,
      @required this.direction,
      @required this.serviceType,
      @required this.orig,
      @required this.dest,
      @required this.dataTimestamp});

  factory BusRoute.fromJson(Map<String, dynamic> json, String operator) {
    return BusRoute(
        co: operator == "TI" ? "KMB/LWB" : json['co'],
        route: json['route'],
        direction: operator == "TI" ? (json['bound'] == "I" ? "inbound": "outbound"): json['bound'],
        serviceType: json['service_type'],
        orig: new IntlString(
          en: json['orig_en'],
          tc: json['orig_tc'],
          sc: json['orig_sc'],
        ),
        dest: new IntlString(
          en: json['dest_en'],
          tc: json['dest_tc'],
          sc: json['dest_sc'],
        ),
        dataTimestamp: json['data_timestamp']);
  }

  factory BusRoute.fromBravo(Map<String, dynamic> json, String direction, bool isInvert) {
    return BusRoute(
        co: json['co'],
        route: json['route'],
        direction: direction,
        serviceType: json['service_type'],
        orig: isInvert ? new IntlString(
          en: json['dest_en'],
          tc: json['dest_tc'],
          sc: json['dest_sc'],
        ) : new IntlString(
          en: json['orig_en'],
          tc: json['orig_tc'],
          sc: json['orig_sc'],
        ),
        dest: isInvert? new IntlString(
          en: json['orig_en'],
          tc: json['orig_tc'],
          sc: json['orig_sc'],
        ) : new IntlString(
          en: json['dest_en'],
          tc: json['dest_tc'],
          sc: json['dest_sc'],
        ),
        dataTimestamp: json['data_timestamp']);
  }
}
