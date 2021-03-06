
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:time_constraint/RequestAssistant.dart';

class AssistantMethods {

  static String key = "AIzaSyCX5sutODXIcV4NT5gQwHOkYAjW-ZRbweo";
  static const maxRes = 20;
  static LatLng? currentLocation;

  static Future<LatLng> getCurrentLocation() async {
    var position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    var lat = position.latitude;
    var long = position.longitude;

    return LatLng(lat, long);
  }

  static Future<String> getLocationName(LatLng position) async {

    String addr = "";
    String url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$key";

    var response = await RequestAssistant.getRequest(url);

    if (response != "Failed" && response["status"] == "OK") {
      addr = response["results"][0]["formatted_address"];
    }

    return addr;

  }

  static Future<List<PointLatLng>> getRoute(LatLng curr, LatLng dest) async {

    PolylinePoints polylinePoints = PolylinePoints();
    String param = "origin=${curr.latitude},${curr.longitude}&destination=${dest.latitude},${dest.longitude}";
    String url = "https://maps.googleapis.com/maps/api/directions/json?$param&key=$key";

    String polylineCode = "";

    var response = await RequestAssistant.getRequest(url);

    if (response != "Failed" && response["status"] == "OK") {
      polylineCode = response["routes"][0]["overview_polyline"]["points"];
    }

    if (polylineCode != "") {
      return polylinePoints.decodePolyline(polylineCode);
    }

    return Future.error("No route found");
  }

  static Future<List<Map<String,String>>> getSearchLocation(String search) async {

    if (currentLocation == null) {
      currentLocation = await getCurrentLocation();
    }

    List<Map<String,String>> locations = [];
    String searchForUrl = search;

    if (search.contains(" ")) {
      searchForUrl = search.replaceAll(RegExp(r"\s+"), "+");
    }

    String param = "key=$key&location=${currentLocation!.latitude},${currentLocation!.longitude}";
    String optional = "rankby=distance&keyword=$searchForUrl";

    String url = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?$param&$optional";
    var response = await RequestAssistant.getRequest(url);
    if (response != "Failed" && response["status"] == "OK") {
      List<dynamic> results = response["results"];

      for (var result in results) {
        if (result != []) {
          Map<String,String> map = {
            "name" : result["name"].toString(),
            "address" : result["vicinity"].toString(),
            "lat" : result["geometry"]["location"]["lat"].toString(),
            "lng" : result["geometry"]["location"]["lng"].toString()
          };
          locations.add(map);
        }
      }
    }

    return locations;
  }
}
