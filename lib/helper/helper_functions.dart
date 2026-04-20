import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../user_info.dart';
import '../widgets/snackbar.dart';
import '../models/direction_details.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class HelperFunctions {
  //for drawer to retrieving user data from database and save it in user_info.dart file variables
  //Future<void> 
  retrieveUserData(BuildContext context) async {
    String status = "";
    DatabaseReference usersReference = FirebaseDatabase.instance
        .ref()
        .child("allUsers")
        .child(FirebaseAuth.instance.currentUser!.uid);

    await usersReference.once().then((onValue) {
      if (onValue.snapshot.value != null) {
        nameOfUser = (onValue.snapshot.value as Map)["name"];
        phoneOfUser = (onValue.snapshot.value as Map)["phone"];
        emailOfUser = (onValue.snapshot.value as Map)["email"];

        status = "success";
      } else {
        displaySnackBar("your record not found.", context);

        FirebaseAuth.instance.signOut();

        status = "error";
      }
    });

    return status;
  }

  String fareAmountCalculation(
    DirectionDetails directionDetails,
    String carType,
  ) {
    double perKmCharges = 0.8;
    double perMinuteCharges = 0.5;
    double baseFareCharges = 2.5;

    double traveledDistanceFareAmount =
        (directionDetails.distanceValue! / 1000) * perKmCharges;
    double durationSpendFareAmount =
        (directionDetails.durationValue! / 60) * perMinuteCharges;

    /* if (carType == "CarX") {
      double totalFareAmount =
          (traveledDistanceFareAmount +
          durationSpendFareAmount +
          baseFareCharges);
      return totalFareAmount.toStringAsFixed(1);
    } else if (carType == "CarXL") {
      double totalFareAmount =
          (traveledDistanceFareAmount +
              durationSpendFareAmount +
              baseFareCharges) *
          2;
      return totalFareAmount.toStringAsFixed(1);
    } else if (carType == "CarSUV") {
      double totalFareAmount =
          (traveledDistanceFareAmount +
              durationSpendFareAmount +
              baseFareCharges) *
          3;
      return totalFareAmount.toStringAsFixed(1);
    } else if (carType == "SportsCar") {
      double totalFareAmount =
          (traveledDistanceFareAmount +
              durationSpendFareAmount +
              baseFareCharges) *
          5;
      return totalFareAmount.toStringAsFixed(1);
    }
    return "0.0";*/
    double multiplier = 1;

    if (carType == "CarXL")
      multiplier = 2;
    else if (carType == "CarSUV")
      multiplier = 3;
    else if (carType == "SportsCar")
      multiplier = 5;

    double totalFare =
        (traveledDistanceFareAmount +
            durationSpendFareAmount +
            baseFareCharges) *
        multiplier;

    return totalFare.toStringAsFixed(1);
  }

  dialPhoneNumber(String phoneNumber) async {
    final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);

    print("Checking dialer support for: $telUri");

    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri, mode: LaunchMode.externalApplication);
    } else {
      print("❌ Could not launch dialer for $phoneNumber");
    }
  }
}
