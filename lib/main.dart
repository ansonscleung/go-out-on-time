import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'types/routes.dart';
import 'package:collection/collection.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

Future<RouteList> fetchKMBRoutes() async {
  final response =
      await http.get(Uri.https('data.etabus.gov.hk', 'v1/transport/kmb/route'));
  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return RouteList.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load KMBRouteList');
  }
}

Future<RouteList> fetchNWFBRoutes() async {
  final response =
  await http.get(Uri.https('rt.data.gov.hk', 'v1/transport/citybus-nwfb/route/nwfb'));
  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return RouteList.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load NWFBRouteList');
  }
}

Future<RouteList> fetchCTBRoutes() async {
  final response =
  await http.get(Uri.https('rt.data.gov.hk', 'v1/transport/citybus-nwfb/route/ctb'));
  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return RouteList.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load CTBRouteList');
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: FutureBuilder<List<RouteList>>(
          future: Future.wait([futureKMBRouteList, futureNWFBRouteList, futureCTBRouteList]),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var mainList = snapshot.data[0].data + snapshot.data[1].data + snapshot.data[2].data;
              return ListView(
                padding: EdgeInsets.all(8),
                children: (mainList..sort((a, b) => compareNatural(a.route, b.route)))
                    .map((route) => Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: Text(route.route ?? ""),
                                title: Text(route.destEN ?? ""),
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

            // By default, show a loading spinner.
            return CircularProgressIndicator();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
