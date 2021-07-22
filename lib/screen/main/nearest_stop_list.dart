import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geodesy/geodesy.dart';
import 'package:go_out_on_time/types/stop.dart';
import 'package:go_out_on_time/utils/distance.dart';
import 'package:go_out_on_time/utils/get_location.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';

import 'package:go_out_on_time/types/routes.dart';
import 'package:location/location.dart';

Future<StopList> fetchKMBStops() async {
  final response =
      await http.get(Uri.https('data.etabus.gov.hk', 'v1/transport/kmb/stop'));
  if (response.statusCode == 200) {
    return StopList.fromJson(jsonDecode(response.body), "TI");
  } else {
    throw Exception('Failed to load KMBStopList');
  }
}

class NearestStopListWidget extends StatefulWidget {
  @override
  _NearestStopListWidgetState createState() => _NearestStopListWidgetState();
}

class _NearestStopListWidgetState extends State<NearestStopListWidget> {
  Future<StopList> futureKMBStopList;

  @override
  void initState() {
    super.initState();
    futureKMBStopList = fetchKMBStops();
  }

  @override
  Widget build(BuildContext context) {
    Future<LocationData> currentLocation = getLocation();
    return Center(
      child: FutureBuilder<List<dynamic>>(
        future: Future.wait([futureKMBStopList, currentLocation]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var mainList = snapshot.data[0].data;
            var location = snapshot.data[1];
            return ListView(
              padding: EdgeInsets.all(8),
              children: (mainList
                    ..sort((a, b) => compareNatural(a.stop,
                        b.stop))) //.where((element) => element.route.startsWith(searchRoute))
                  .map(
                    (stop) => StopCard(stop, location),
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

class StopCard extends StatefulWidget {
  Stop stop;
  LocationData locationData;
  StopCard(this.stop, this.locationData);

  @override
  _StopCardState createState() => _StopCardState();
}

class _StopCardState extends State<StopCard> {
  @override
  Widget build(BuildContext context) {
    LatLng stopLoc = LatLng(widget.stop.lat, widget.stop.long);
    LatLng currLoc =
        LatLng(widget.locationData.latitude, widget.locationData.longitude);
    num dist = distance(stopLoc, currLoc);
    return GestureDetector(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
                //leading: Text(route.route ?? ""),
                title: Text(widget.stop.name
                        .localeString(Localizations.localeOf(context)) ??
                    ""),
                subtitle: Text(dist > 1000
                    ? AppLocalizations.of(context)
                        .kilometre((dist / 1000).toStringAsFixed(2))
                    : AppLocalizations.of(context)
                        .metre(dist.toStringAsFixed(0)))),
          ],
        ),
      ),
      /*onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => RouteScreen(stop)))*/
    );
  }
}
