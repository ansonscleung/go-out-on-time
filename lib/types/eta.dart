import 'package:flutter/material.dart';

import 'common.dart';

class ETAList {
  final String type;
  final String version;
  final String generatedTimestamp;
  final List<ETA> data;

  ETAList(
      {@required this.type,
      @required this.version,
      @required this.generatedTimestamp,
      this.data});

  factory ETAList.fromJson(Map<String, dynamic> json) {
    return ETAList(
        type: json['type'],
        version: json['version'],
        generatedTimestamp: json['generated_timestamp'],
        data: (json['data'] as List)
            ?.map((stop) => ETA.fromJson(stop))
            ?.toList());
  }
}

class ETA {
  final String co;
  final String route;
  final String direction;
  final String serviceType;
  final int seq;
  final IntlString dest;
  final int etaSeq;
  final DateTime eta;
  final IntlString remark;
  final String dataTimestamp;

  ETA(
      {@required this.co,
      @required this.route,
      @required this.direction,
      @required this.serviceType,
      @required this.seq,
      @required this.dest,
      @required this.etaSeq,
      this.eta,
      @required this.remark,
      @required this.dataTimestamp});

  factory ETA.fromJson(Map<String, dynamic> json) =>
      ETA(
          co: json['co'],
          route: json['route'],
          direction: json['dir'] == "I" ? "inbound" : "outbound",
          serviceType: json['service_type'].toString(),
          seq: int.parse(json['seq'].toString()),
          dest: new IntlString(
            en: json['dest_en'],
            tc: json['dest_tc'],
            sc: json['dest_sc'],
          ),
          etaSeq: int.parse(json['eta_seq'].toString()),
          eta: json['eta'] != null ? DateTime.parse(json['eta']) : null,
          remark: new IntlString(
            en: json['rmk_en'],
            tc: json['rmk_tc'],
            sc: json['rmk_sc'],
          ),
          dataTimestamp: json['data_timestamp']);
}
