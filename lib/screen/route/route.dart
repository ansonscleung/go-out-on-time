import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_out_on_time/types/route_stop.dart';
import 'package:go_out_on_time/types/routes.dart';
import 'package:go_out_on_time/types/stop.dart';
import 'package:http/http.dart' as http;

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
                                  ListTile(
                                    leading: Text(stop.seq.toString() ?? ""),
                                    title: Text(stop.stopInfo?.name
                                            ?.localeString(
                                                Localizations.localeOf(
                                                    context)) ??
                                        ""),
                                    /*subtitle: Text(stop.stop.toString() ??
                                        ""),*/
                                  ),
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
