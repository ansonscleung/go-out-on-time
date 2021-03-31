import 'package:flutter/material.dart';

class RouteList {
  final String type;
  final String version;
  final String generatedTimestamp;
  final List<Route> data;

  RouteList(
      {@required this.type,
      @required this.version,
      @required this.generatedTimestamp,
      this.data});

  factory RouteList.fromJson(Map<String, dynamic> json) {
    return RouteList(
        type: json['type'],
        version: json['version'],
        generatedTimestamp: json['generated_timestamp'],
        data: (json['data'] as List)?.map((route) => Route.fromJson(route))?.toList());
  }
}

class Route {
  final String co;
  final String route;
  final String bound;
  final String serviceType;
  final String origEN;
  final String origTC;
  final String origSC;
  final String destEN;
  final String destTC;
  final String destSC;
  final String dataTimestamp;

  Route(
      {@required this.co,
      @required this.route,
      @required this.bound,
      @required this.serviceType,
      @required this.origEN,
      @required this.origTC,
      @required this.origSC,
      @required this.destEN,
      @required this.destTC,
      @required this.destSC,
      @required this.dataTimestamp});

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
        co: json['co'],
        route: json['route'],
        bound: json['bound'],
        serviceType: json['service_type'],
        origEN: json['orig_en'],
        origTC: json['orig_tc'],
        origSC: json['orig_sc'],
        destEN: json['dest_en'],
        destTC: json['dest_tc'],
        destSC: json['dest_sc'],
        dataTimestamp: json['data_timestamp']);
  }
}
