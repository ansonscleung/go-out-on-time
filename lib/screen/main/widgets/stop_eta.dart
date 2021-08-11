import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geodesy/geodesy.dart';
import 'package:go_out_on_time/screen/route/route.dart';
import 'package:go_out_on_time/types/eta.dart';
import 'package:go_out_on_time/types/route_stop.dart';
import 'package:go_out_on_time/types/routes.dart';
import 'package:go_out_on_time/types/stop.dart';
import 'package:go_out_on_time/utils/distance.dart';
import 'package:go_out_on_time/utils/get_location.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:marquee/marquee.dart';
import 'package:timeago_flutter/timeago_flutter.dart';

Future<ETAList> fetchKMBStopETAList(Stop stop) async {
  final response = await http.get(Uri.https(
      'data.etabus.gov.hk', 'v1/transport/kmb/stop-eta/${stop.stop}'));
  if (response.statusCode == 200) {
    return ETAList.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load KMBStopETA');
  }
}

class StopETAWidget extends StatefulWidget {
  final Stop stop;
  StopETAWidget(this.stop);

  @override
  _ETAWidgetState createState() => _ETAWidgetState();
}

class _ETAWidgetState extends State<StopETAWidget> {
  Future<ETAList> futureKMBStopETAList;

  @override
  void initState() {
    super.initState();
    futureKMBStopETAList = fetchKMBStopETAList(widget.stop);
    localesMap.forEach((locale, lookupMessages) {
      setLocaleMessages(locale, lookupMessages);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ETAList>(
      future: futureKMBStopETAList,
      builder: (_context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.data.isNotEmpty &&
              snapshot.data.data[0].eta == null) {
            return Center(
              child: Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Text(snapshot.data.data[0].remark
                      .localeString(Localizations.localeOf(context)))),
            );
          }
          var effectiveETAs = snapshot.data.data.where(
              (eta) => eta.eta != null && !eta.eta.isBefore(DateTime.now()));
          List<ETA> effectiveFirstETAs = [];
          effectiveETAs.forEach((eta) {
            int routeETAIndex = effectiveFirstETAs.indexWhere((firstETA) =>
                firstETA.route == eta.route &&
                firstETA.direction == eta.direction);
            if (routeETAIndex == -1) {
              effectiveFirstETAs.add(eta);
            }
          });
          return effectiveFirstETAs.isNotEmpty
              ? Table(
                  columnWidths: {
                    0: FlexColumnWidth(2),
                    1: FlexColumnWidth(7),
                    2: FlexColumnWidth(5),
                  },
                  children: effectiveFirstETAs
                      .map(
                        (eta) => TableRow(
                          children: [
                            Text(eta.route ?? ""),
                            Marquee(text: eta.dest.localeString(
                                    Localizations.localeOf(context)) ??
                                ""),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text((eta.eta != null)
                                        ? DateFormat("HH:mm")
                                            .format(eta.eta.toLocal())
                                        : ""),
                                    Timeago(
                                        builder: (_, value) => Text(value),
                                        date: eta.eta,
                                        locale: Localizations.localeOf(context)
                                            .toLanguageTag(),
                                        allowFromNow: true)
                                  ],
                                ),
                                if (eta.remark.localeString(
                                        Localizations.localeOf(context)) !=
                                    '')
                                  Text(eta.remark.localeString(
                                      Localizations.localeOf(context))),
                              ],
                            ),
                          ],
                        ),
                      )
                      .toList(),
                )
              : Center(
                  child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      child: Text(AppLocalizations.of(context).noETA)),
                );
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        }
        return LinearProgressIndicator();
      },
    );
  }
}
