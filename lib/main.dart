import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:collection/collection.dart';

import 'types/routes.dart';

void main() {
  runApp(GoOutOnTime());
}

Future<RouteList> fetchKMBRoutes() async {
  final response =
      await http.get(Uri.https('data.etabus.gov.hk', 'v1/transport/kmb/route'));
  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return RouteList.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load KMBRouteList');
  }
}

Future<RouteList> fetchNWFBRoutes() async {
  final response = await http
      .get(Uri.https('rt.data.gov.hk', 'v1/transport/citybus-nwfb/route/nwfb'));
  if (response.statusCode == 200) {
    return RouteList.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load NWFBRouteList');
  }
}

Future<RouteList> fetchCTBRoutes() async {
  final response = await http
      .get(Uri.https('rt.data.gov.hk', 'v1/transport/citybus-nwfb/route/ctb'));
  if (response.statusCode == 200) {
    return RouteList.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load CTBRouteList');
  }
}

class GoOutOnTime extends StatefulWidget {
  @override
  _GoOutOnTimeState createState() => _GoOutOnTimeState();

  static _GoOutOnTimeState of(BuildContext context) =>
      context.findAncestorStateOfType<_GoOutOnTimeState>();
}

class _GoOutOnTimeState extends State<GoOutOnTime> {
  Locale _locale;

  void setLocale(Locale value) {
    setState(() {
      _locale = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go Out On Time',
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''),
        const Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
        const Locale.fromSubtags(
            languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'),
      ],
      locale: _locale,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    return Scaffold(
      appBar: AppBar(
          title: Text(AppLocalizations.of(context).goOutOnTime),
          actions: <Widget>[
            PopupMenuButton(
              onSelected: (result) {
                GoOutOnTime.of(context)
                  .setLocale(result); },
              itemBuilder: (BuildContext context) => <PopupMenuEntry>[
                 PopupMenuItem(
                  value: Locale("en"),
                  child: Text('English'),
                ),
                 PopupMenuItem(
                  value: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
                  child: Text('Trad'),
                ),
              ],
            ),
          ]),
      body: Center(
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
                children:
                    (mainList..sort((a, b) => compareNatural(a.route, b.route)))
                        .map((route) => Card(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  ListTile(
                                    leading: Text(route.route ?? ""),
                                    title: Text(route.dest.localeString(Localizations.localeOf(context)) ?? ""),
                                    subtitle: Text(route.co ?? ""),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
              );
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
