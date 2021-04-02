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

  factory RouteList.fromJson(Map<String, dynamic> json, {bool isKMB = false}) {
    return RouteList(
        type: json['type'],
        version: json['version'],
        generatedTimestamp: json['generated_timestamp'],
        // TODO: Logic to generate inbound/outbound route for Bravo Routes
        data: (json['data'] as List)
            ?.map((route) => BusRoute.fromJson(route, isKMB: isKMB))
            ?.toList());
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

  factory BusRoute.fromJson(Map<String, dynamic> json, {bool isKMB = false}) {
    return BusRoute(
        co: isKMB ? "KMB/LWB" : json['co'],
        route: json['route'],
        direction: isKMB ? (json['bound'] == "I" ? "inbound": "outbound"): json['bound'],
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
}
