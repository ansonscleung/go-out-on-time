import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_out_on_time/types/eta.dart';
import 'package:go_out_on_time/types/route_stop.dart';
import 'package:go_out_on_time/types/routes.dart';
import 'package:go_out_on_time/types/stop.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

Future<RouteStopList> fetchRouteStopList(BusRoute route) async {
  final response = await http.get(route.co == "KMB/LWB"
      ? Uri.https('data.etabus.gov.hk',
          'v1/transport/kmb/route-stop/${route.route}/${route.direction}/${route.serviceType}')
      : Uri.https('rt.data.gov.hk',
          'v1/transport/citybus-nwfb/route-stop/${route.co}/${route.route}/inbound'));
  if (response.statusCode == 200) {
    var routeStopList = RouteStopList.fromJson(jsonDecode(response.body),
        isKMB: route.co == "KMB/LWB");
    await Future.wait(routeStopList.data.map((routeStop) async {
      final stopResponse = await http.get(route.co == "KMB/LWB"
          ? Uri.https(
              'data.etabus.gov.hk', 'v1/transport/kmb/stop/${routeStop.stop}')
          : Uri.https('rt.data.gov.hk',
              'v1/transport/citybus-nwfb/stop/${routeStop.stop}'));
      if (stopResponse.statusCode == 200) {
        routeStop.stopInfo = Stop.fromJson(jsonDecode(stopResponse.body));
      } else {
        throw Exception('Failed to load stop ${routeStop.stop}');
      }
    }));
    return routeStopList;
  } else {
    throw Exception('Failed to load RouteStopList');
  }
}

Future<ETAList> fetchETA(BusRoute route, String stop) async {
  final response = await http.get(route.co == "KMB/LWB"
      ? Uri.https('data.etabus.gov.hk',
          'v1/transport/kmb/eta/$stop/${route.route}/${route.serviceType}')
      : Uri.https('rt.data.gov.hk',
          '/v1/transport/citybus-nwfb/eta/${route.co}/$stop/${route.route}'));
  if (response.statusCode == 200) {
    return ETAList.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load ETA');
  }
}

class RouteScreen extends StatefulWidget {
  final BusRoute route;
  RouteScreen(this.route);

  @override
  _RouteScreenState createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  Future<RouteStopList> futureRouteStopList;

  @override
  void initState() {
    super.initState();
    futureRouteStopList = fetchRouteStopList(widget.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('New Screen')),
        body: Center(
          child: FutureBuilder<RouteStopList>(
            future: futureRouteStopList,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView(
                  padding: EdgeInsets.all(8),
                  children: snapshot.data.data
                      .map(
                        (stop) => GestureDetector(
                            child: Card(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ExpansionTile(
                                      leading: Text(stop.seq.toString() ?? ""),
                                      title: Text(stop.stopInfo?.name
                                              ?.localeString(
                                                  Localizations.localeOf(
                                                      context)) ??
                                          ""),
                                      children: <Widget>[
                                        ETAWidget(widget.route, stop.stop)
                                      ]),
                                ],
                              ),
                            ),
                            onTap: () => {}),
                      )
                      .toList(),
                );
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              return CircularProgressIndicator();
            },
          ),
        ));
  }
}

final localesMap = <String, LookupMessages>{
  'zh-Hant-HK': CustomZhMessages(),
  'zh-Hans-CN': ZhCnMessages(),
  'en': EnShortMessages(),
};

final localeList = [...localesMap.keys];

class CustomZhMessages extends ZhMessages {
  @override
  String suffixFromNow() => '';
  @override
  String lessThanOneMinute(int seconds) => '即將到達';
  @override
  String aboutAMinute(int minutes) => '約 1 分鐘';
  @override
  String minutes(int minutes) => '${minutes} 分鐘';
}

class ETAWidget extends StatefulWidget {
  final BusRoute route;
  final String stop;
  ETAWidget(this.route, this.stop);

  @override
  _ETAWidgetState createState() => _ETAWidgetState();
}

class _ETAWidgetState extends State<ETAWidget> {
  Future<ETAList> futureETA;

  @override
  void initState() {
    super.initState();
    futureETA = fetchETA(widget.route, widget.stop);
    localesMap.forEach((locale, lookupMessages) {
      setLocaleMessages(locale, lookupMessages);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ETAList>(
      future: futureETA,
      builder: (_context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.data.isNotEmpty && snapshot.data.data[0].eta == null) {
            return Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(snapshot.data.data[0].remark.localeString(
                Localizations.localeOf(context))));
          }
          var effectiveETAs = snapshot.data.data.where((eta) =>
              eta.direction == widget.route.direction &&
              (eta.eta != null && !eta.eta.isBefore(DateTime.now())));
          return Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: effectiveETAs.isNotEmpty
                  ? Table(
                      columnWidths: {
                        0: FlexColumnWidth(1),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(2),
                      },
                      children: effectiveETAs
                          .map(
                            (eta) => TableRow(
                              children: [
                                Center(
                                    child: Text((eta.eta != null)
                                        ? DateFormat("HH:mm")
                                            .format(eta.eta.toLocal())
                                        : "")),
                                Center(
                                    child: Timeago(
                                        builder: (_, value) => Text(value),
                                        date: eta.eta,
                                        locale: Localizations.localeOf(context)
                                            .toLanguageTag(),
                                        allowFromNow: true)),
                                Center(
                                  child: Text(eta.remark.localeString(
                                      Localizations.localeOf(context))),
                                ),
                              ],
                            ),
                          )
                          .toList(),
                    )
                  : Text(AppLocalizations.of(context).noETA));
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return CircularProgressIndicator();
      },
    );
  }
}
