import 'package:geodesy/geodesy.dart';

num distance(LatLng from, LatLng to) {
  Geodesy geodesy = Geodesy();

  return geodesy.distanceBetweenTwoGeoPoints(from, to);
}