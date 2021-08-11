import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';
import 'package:go_out_on_time/screen/main/nearest_stop_list.dart';
import 'package:go_out_on_time/screen/main/route_list.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:collection/collection.dart';

import 'screen/route/route.dart';
import 'types/routes.dart';

void main() {
  runApp(GoOutOnTime());
}

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
  SearchBar searchBar;
  String searchRoute = "1";

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(AppLocalizations.of(context).goOutOnTime),
      actions: <Widget>[
        searchBar.getSearchAction(context),
        PopupMenuButton(
          onSelected: (result) {
            GoOutOnTime.of(context).setLocale(result);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry>[
            PopupMenuItem(
              value: Locale("en"),
              child: Text('English'),
            ),
            PopupMenuItem(
              value: Locale.fromSubtags(
                  languageCode: 'zh', scriptCode: 'Hant', countryCode: 'HK'),
              child: Text('Trad'),
            ),
          ],
        ),
      ],
      bottom: TabBar(
        tabs: [
          Tab(icon: Icon(Icons.directions_car)),
          Tab(icon: Icon(Icons.directions_transit)),
        ],
      ),
    );
  }

  _HomePageState() {
    searchBar = new SearchBar(
        setState: setState,
        onSubmitted: (search) {
          searchRoute = search;
        },
        buildDefaultAppBar: buildAppBar);
  }
  @override
  void initState() {
    super.initState();
    futureKMBRouteList = fetchKMBRoutes();
    futureNWFBRouteList = fetchNWFBRoutes();
    futureCTBRouteList = fetchCTBRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: searchBar.build(context),
        body: TabBarView(
          children: [
            RouteListWidget(
              searchRoute: searchRoute,
            ),
            NearestStopListWidget(),
          ],
        ),
      ),
    );
  }
}
