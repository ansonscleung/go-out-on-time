import 'dart:convert';
import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geodesy/geodesy.dart' as geodesy;
import 'package:go_out_on_time/types/eta.dart';
import 'package:go_out_on_time/types/route_stop.dart';
import 'package:go_out_on_time/types/routes.dart';
import 'package:go_out_on_time/types/stop.dart';
import 'package:go_out_on_time/utils/distance.dart';
import 'package:go_out_on_time/utils/get_location.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart';
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

  Completer<GoogleMapController> _controller = Completer();
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  MarkerId selectedMarker;
  int _markerIdCounter = 1;

  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Future<void> _goToPosition(double lat, double long) async {
    CameraPosition _position = CameraPosition(
      target: LatLng(lat, long),
      zoom: 19,
    );
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_position));
  }

  @override
  void initState() {
    super.initState();
    futureRouteStopList = fetchRouteStopList(widget.route);
  }

  void _add(int index, RouteStop stop) {
    final String markerIdVal = 'marker_id_$_markerIdCounter';
    _markerIdCounter++;
    final MarkerId markerId = MarkerId(markerIdVal);

    final Marker marker = Marker(
      markerId: markerId,
      position: LatLng(stop.stopInfo.lat, stop.stopInfo.long),
      infoWindow: InfoWindow(title: stop.stopInfo.name.localeString(Localizations.localeOf(context))),
      onTap: () {
        _goToPosition(stop.stopInfo.lat, stop.stopInfo.long);
      },
    );

    setState(() {
      markers[markerId] = marker;
    });
  }

  @override
  Widget build(BuildContext context) {
    Future<LocationData> currentLocation = getLocation();
    String routeDetail = AppLocalizations.of(context).fromTo(
        widget.route.orig.localeString(Localizations.localeOf(context)),
        widget.route.dest.localeString(Localizations.localeOf(context)));
    return Scaffold(
        appBar: AppBar(
            title:
                Text('${widget.route.co} ${widget.route.route} $routeDetail')),
        body: Column(
          children: [
            SizedBox(
              height: 250,
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: _kGooglePlex,
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                },
                markers: Set<Marker>.of(markers.values),
              ),
            ),
            Expanded(
              child: Center(
                child: FutureBuilder<LocationData>(
                  future: currentLocation,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      var location = snapshot.data;
                      return FutureBuilder<RouteStopList>(
                        future: futureRouteStopList,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            List<RouteStop> stopWithDistance =
                                snapshot.data.data.map((stop) {
                              geodesy.LatLng stopLoc = geodesy.LatLng(
                                  stop.stopInfo.lat, stop.stopInfo.long);
                              geodesy.LatLng currLoc = geodesy.LatLng(
                                  location.latitude, location.longitude);
                              stop.stopInfo.distance =
                                  distance(stopLoc, currLoc);
                              return stop;
                            }).toList();
                            List<RouteStop> nearStops = stopWithDistance
                                .where((stop) => stop.stopInfo.distance < 500)
                                .toList();
                            String nearestStop = nearStops.isNotEmpty
                                ? nearStops
                                        ?.reduce((curr, next) =>
                                            curr.stopInfo.distance <
                                                    next.stopInfo.distance
                                                ? curr
                                                : next)
                                        ?.stop ??
                                    ""
                                : "";
                            snapshot.data.data.asMap().forEach((index, stop) =>
                                Future.delayed(Duration.zero, () =>
                                  _add(index, stop)));
                            return ListView(
                              padding: EdgeInsets.all(8),
                              children: stopWithDistance.map(
                                (stop) {
                                  return GestureDetector(
                                      child: Card(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: <Widget>[
                                            ExpansionTile(
                                              leading: Text(
                                                  stop.seq.toString() ?? ""),
                                              title: Text(stop.stopInfo?.name
                                                      ?.localeString(
                                                          Localizations
                                                              .localeOf(
                                                                  context)) ??
                                                  ""),
                                              subtitle: Text(stop
                                                          .stopInfo.distance >
                                                      1000
                                                  ? AppLocalizations.of(context)
                                                      .kilometre((stop.stopInfo
                                                                  .distance /
                                                              1000)
                                                          .toStringAsFixed(2))
                                                  : AppLocalizations.of(context)
                                                      .metre(stop
                                                          .stopInfo.distance
                                                          .toStringAsFixed(0))),
                                              children: <Widget>[
                                                ETAWidget(
                                                    widget.route, stop.stop)
                                              ],
                                              initiallyExpanded:
                                                  nearestStop == stop.stop,
                                            ),
                                          ],
                                        ),
                                      ),
                                      onTap: () {
                                        _goToPosition(stop.stopInfo.lat,
                                            stop.stopInfo.long);
                                      });
                                },
                              ).toList(),
                            );
                          } else if (snapshot.hasError) {
                            return Text("${snapshot.error}");
                          }
                          return CircularProgressIndicator();
                        },
                      );
                    } else if (snapshot.hasError) {
                      return Text("${snapshot.error}");
                    }
                    return CircularProgressIndicator();
                  },
                ),
              ),
            ),
          ],
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
          if (snapshot.data.data.isNotEmpty &&
              snapshot.data.data[0].eta == null) {
            return Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(snapshot.data.data[0].remark
                    .localeString(Localizations.localeOf(context))));
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
