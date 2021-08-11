import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_out_on_time/screen/main/widgets/stop_eta.dart';
import 'package:go_out_on_time/types/stop.dart';

class StopCard extends StatefulWidget {
  final Stop stop;
  StopCard(this.stop);

  @override
  _StopCardState createState() => _StopCardState();
}

class _StopCardState extends State<StopCard> {
  @override
  Widget build(BuildContext context) {
    String stationName = widget.stop.name
        .localeString(Localizations.localeOf(context)) ??
        "";
    String distance = widget.stop.distance > 1000
        ? AppLocalizations.of(context)
        .kilometre((widget.stop.distance / 1000).toStringAsFixed(2))
        : AppLocalizations.of(context)
        .metre(widget.stop.distance.toStringAsFixed(0));
    return GestureDetector(
      child: Card(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              //leading: Text(route.route ?? ""),
                title: Text('$stationName, $distance'),
                subtitle: StopETAWidget(widget.stop)),
          ],
        ),
      ),
      /*onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => RouteScreen(stop)))*/
    );
  }
}
