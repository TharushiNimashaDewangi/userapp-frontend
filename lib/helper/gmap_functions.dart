import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';//latlng
import 'package:user_app_frontend/models/address.dart';
import 'package:user_app_frontend/manageInfo/manage_info.dart';
import 'package:user_app_frontend/map_info.dart';
import 'package:user_app_frontend/models/direction_details.dart';

class GmapFunctions {
  //we use asny because we wanted to wait until we get the response from api and then we will return the data to the function which call this function
  static Future<dynamic> requestAPI(String url) async {
    print("REQUEST URL: $url");
    http.Response apiResponse = await http.get(Uri.parse(url));
    print("STATUS CODE: ${apiResponse.statusCode}"); // 👈 ADD
    print("RAW RESPONSE: ${apiResponse.body}"); // 👈 ADD
    try {
      if (apiResponse.statusCode == 200) {
        String responseData = apiResponse.body;
        var decodedData = jsonDecode(
          responseData,
        ); //jsonDecode is used to convert the response data from string to json format so that we can use it in our app
        return decodedData;
      } else {
        return "error";
      }
    } catch (msg) {
      print(msg);
      return "error";
    }
  }

  static Future<String> getHumanReadableAddressFromGeoGraphicCoOrdinates(
    Position positionUser,
    BuildContext context,
  ) async {
    String userAddressInReadableFormat = "";
    //get the address of the user from the geographic co-ordinates using google map geocoding api
    //1
    String urlGeoCodingApi =
        "https://maps.googleapis.com/maps/api/geocode/json?latlng=${positionUser.latitude},${positionUser.longitude}&key=$gMapKey"; //gMapKey in map_info.dart

    var responseData = await requestAPI(urlGeoCodingApi);

    if (responseData != "error") {
      Address address = Address();
      address.userAddressInReadableFormat =
          responseData["results"][0]["formatted_address"];
      address.placeID = responseData["results"][0]["place_id"];
      address.placeName = responseData["results"][0]["formatted_address"];
      address.latPosition = positionUser.latitude;
      address.lngPosition = positionUser.longitude;

      //state management using provider to save the pick up address in manageInfo class which we can use it anywhere in our app
      Provider.of<ManageInfo>(
        context,
        listen: false,
      ).updatePickUpAddress(address);
    } else {
      print("try Again. Error Occurred.");
    }

    return responseData["results"][0]["formatted_address"];
  }

  static Future<DirectionDetails?> fetchDirectionDetailsFromAPI(
    LatLng pickup,
    LatLng destination,
  ) async {
    //direction details api url to get the direction details for the trip from pickup location to drop off destination location using google map direction api
    //need to enable google map direction api in google cloud console and then we can use that api to get the direction 
    //details for the trip from pickup location to drop off destination location
    //5
    String directionDetailsAPIUrl =
        "https://maps.googleapis.com/maps/api/directions/json?destination=${destination.latitude},${destination.longitude}&origin=${pickup.latitude},${pickup.longitude}&key=$gMapKey";

    var directionDetailsAPIResponseData = await requestAPI(
      directionDetailsAPIUrl,
    );

    if (directionDetailsAPIResponseData == "error") {
      return null;
    }
//direction details is the model class which we have created in 
//direction_details.dart file to save the direction details data 
//which we will get from google map direction api and then we will 
//return that data to the function which call this function
    DirectionDetails details = DirectionDetails();
    details.distance =
        directionDetailsAPIResponseData["routes"][0]["legs"][0]["distance"]["text"];
    details.distanceValue =
        directionDetailsAPIResponseData["routes"][0]["legs"][0]["distance"]["value"];

    details.duration =
        directionDetailsAPIResponseData["routes"][0]["legs"][0]["duration"]["text"];
    details.durationValue =
        directionDetailsAPIResponseData["routes"][0]["legs"][0]["duration"]["value"];

    details.encodedPointsForDrawingRoutes =
        directionDetailsAPIResponseData["routes"][0]["overview_polyline"]["points"];

    return details;
  }
}
