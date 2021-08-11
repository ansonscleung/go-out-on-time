import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';

import 'package:go_out_on_time/screen/route/route.dart';
import 'package:go_out_on_time/types/routes.dart';

Future<RouteList> fetchKMBRoutes() async {
  final response =
      await http.get(Uri.https('data.etabus.gov.hk', 'v1/transport/kmb/route'));
  if (response.statusCode == 200) {
    return RouteList.fromJson(jsonDecode(response.body), "TI");
  } else {
    throw Exception('Failed to load KMBRouteList');
  }
}

Future<RouteList> fetchNWFBRoutes() async {
  final response = await http
      .get(Uri.https('rt.data.gov.hk', 'v1/transport/citybus-nwfb/route/nwfb'));
  if (response.statusCode == 200) {
    var routes = jsonDecode(response.body)['data'];
    bool hasInbound, hasOutbound;
    var result =
        await Future.wait(routes.map<Future<Iterable<BusRoute>>>((route) async {
      final inboundResponse = await http.get(Uri.https('rt.data.gov.hk',
          'v1/transport/citybus-nwfb/route-stop/${route['co']}/${route['route']}/inbound'));
      if (inboundResponse.statusCode == 200) {
        hasInbound = jsonDecode(inboundResponse.body)['data'].isNotEmpty;
      } else {
        throw Exception('Failed to load inbound route of ${route['route']}');
      }
      final outboundResponse = await http.get(Uri.https('rt.data.gov.hk',
          'v1/transport/citybus-nwfb/route-stop/${route['co']}/${route['route']}/outbound'));
      if (outboundResponse.statusCode == 200) {
        hasOutbound = jsonDecode(outboundResponse.body)['data'].isNotEmpty;
      } else {
        throw Exception('Failed to load outbound route of ${route['route']}');
      }
      if (hasInbound && hasOutbound) {
        return [
          BusRoute.fromBravo(route, "inbound", true),
          BusRoute.fromBravo(route, "outbound", false)
        ];
      } else if (hasInbound) {
        return [BusRoute.fromBravo(route, "inbound", false)];
      } else {
        return [BusRoute.fromBravo(route, "outbound", false)];
      }
    }));
    return RouteList.fromBravo(
        jsonDecode(response.body),
        result
            .expand((element) => element)
            .map((route) => route as BusRoute)
            .toList());
  } else {
    throw Exception('Failed to load NWFBRouteList');
  }
}

Future<RouteList> fetchCTBRoutes() async {
  final response = await http
      .get(Uri.https('rt.data.gov.hk', 'v1/transport/citybus-nwfb/route/ctb'));
  if (response.statusCode == 200) {
    var routes = jsonDecode(response.body)['data'];
    bool hasInbound, hasOutbound;
    var result =
        await Future.wait(routes.map<Future<Iterable<BusRoute>>>((route) async {
      final inboundResponse = await http.get(Uri.https('rt.data.gov.hk',
          'v1/transport/citybus-nwfb/route-stop/${route['co']}/${route['route']}/inbound'));
      if (inboundResponse.statusCode == 200) {
        hasInbound = jsonDecode(inboundResponse.body)['data'].isNotEmpty;
      } else {
        throw Exception('Failed to load inbound route of ${route['route']}');
      }
      final outboundResponse = await http.get(Uri.https('rt.data.gov.hk',
          'v1/transport/citybus-nwfb/route-stop/${route['co']}/${route['route']}/outbound'));
      if (outboundResponse.statusCode == 200) {
        hasOutbound = jsonDecode(outboundResponse.body)['data'].isNotEmpty;
      } else {
        throw Exception('Failed to load outbound route of ${route['route']}');
      }
      if (hasInbound && hasOutbound) {
        return [
          BusRoute.fromBravo(route, "inbound", true),
          BusRoute.fromBravo(route, "outbound", false)
        ];
      } else if (hasInbound) {
        return [BusRoute.fromBravo(route, "inbound", false)];
      } else {
        return [BusRoute.fromBravo(route, "outbound", false)];
      }
    }));
    return RouteList.fromBravo(
        jsonDecode(response.body),
        result
            .expand((element) => element)
            .map((route) => route as BusRoute)
            .toList());
  } else {
    throw Exception('Failed to load CTBRouteList');
  }
}

class RouteListWidget extends StatefulWidget {
  final String searchRoute;
  RouteListWidget({this.searchRoute});

  @override
  _RouteListWidgetState createState() => _RouteListWidgetState();
}

class _RouteListWidgetState extends State<RouteListWidget> {
  Future<RouteList> futureKMBRouteList;
  Future<RouteList> futureNWFBRouteList;
  Future<RouteList> futureCTBRouteList;

  @override
  void initState() {
    super.initState();
    futureKMBRouteList = fetchKMBRoutes();
    futureNWFBRouteList = fetchNWFBRoutes();
    futureCTBRouteList = fetchCTBRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<List<RouteList>>(
        future: Future.wait(
            [futureKMBRouteList, futureNWFBRouteList, futureCTBRouteList]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var mainList = snapshot.data[0].data +
                snapshot.data[1].data +
                snapshot.data[2].data;
            return ListView(
              padding: EdgeInsets.all(8),
              children: (mainList
                    ..sort((a, b) => compareNatural(a.route, b.route)))
                  .where(
                      (element) => element.route.startsWith(widget.searchRoute))
                  .map(
                    (route) => GestureDetector(
                        child: Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: Text(route.route ?? ""),
                                title: Text(route.dest.localeString(
                                        Localizations.localeOf(context)) ??
                                    ""),
                                subtitle: Text(route.co ?? ""),
                              ),
                            ],
                          ),
                        ),
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => RouteScreen(route)))),
                  )
                  .toList(),
            );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return CircularProgressIndicator();
        },
      ),
    );
  }
}
