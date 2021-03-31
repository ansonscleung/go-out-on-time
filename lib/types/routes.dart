import 'package:flutter/material.dart';
import 'package:go_out_on_time/types/common.dart';

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
  final IntlString orig;
  final IntlString dest;
  final String dataTimestamp;

  Route(
      {@required this.co,
      @required this.route,
      @required this.bound,
      @required this.serviceType,
      @required this.orig,
      @required this.dest,
      @required this.dataTimestamp});

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
        co: json['co'],
        route: json['route'],
        bound: json['bound'],
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
