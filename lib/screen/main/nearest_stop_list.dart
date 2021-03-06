import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geodesy/geodesy.dart';
import 'package:go_out_on_time/types/stop.dart';
import 'package:go_out_on_time/utils/distance.dart';
import 'package:go_out_on_time/utils/get_location.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';

import 'package:location/location.dart';

import 'widgets/stop_card.dart';

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
      child: FutureBuilder<LocationData>(
        future: currentLocation,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var location = snapshot.data;
            return FutureBuilder<List<StopList>>(
              future: Future.wait([futureKMBStopList]),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var mainList = snapshot.data[0].data;
                  return ListView(
                    padding: EdgeInsets.all(8),
                    children: mainList
                        .expand(
                          (stop) {
                            LatLng stopLoc = LatLng(stop.lat, stop.long);
                            LatLng currLoc =
                                LatLng(location.latitude, location.longitude);
                            stop.distance = distance(stopLoc, currLoc);
                            return stop.distance <= 500 ? [stop] : [];
                          },
                        )
                    .sorted((a, b) => a.distance.compareTo(b.distance))
                        .map(
                          (stop) => StopCard(stop),
                        )
                        .toList(),
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
    );
  }
}

