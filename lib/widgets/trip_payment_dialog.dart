import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';


class TripPaymentDialog extends StatefulWidget {
  String totalFareAmount, carTypeChecker;
  TripPaymentDialog({super.key, required this.totalFareAmount, required this.carTypeChecker});

  @override
  State<TripPaymentDialog> createState() => _TripPaymentDialogState();
}

class _TripPaymentDialogState extends State<TripPaymentDialog> {

  storeFareAmountToDriverEarnings(totalFareAmount) async {
    DatabaseReference earningsRef = FirebaseDatabase.instance.ref()
        .child("allDrivers")
        .child(FirebaseAuth.instance.currentUser!.uid)
        .child("earnings");

    await earningsRef.once().then((dataSnap) {
      if(dataSnap.snapshot.value != null) {
        double oldEarnings = double.parse(dataSnap.snapshot.value.toString());
        double currentTripFareAmount = double.parse(totalFareAmount);

        double driverTotalEarnings = oldEarnings + currentTripFareAmount;

        earningsRef.set(driverTotalEarnings);
      } else {
        earningsRef.set(totalFareAmount);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
      ),
      backgroundColor: Colors.white70,
      child: Container(
        margin: const EdgeInsets.all(5.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            SizedBox(height: 21,),

            Text(
              "${widget.carTypeChecker}'s TRIP Invoice",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold
              ),
            ),

            SizedBox(height: 21,),

            Divider(
              height: 1.5,
              color: Colors.grey,
              thickness: 1.0,
            ),

            SizedBox(height: 16,),

            Text(
              "\$ " + widget.totalFareAmount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 16,),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "This is the ${widget.carTypeChecker}'s fare amount ( \$ ${widget.totalFareAmount} ) to be charged from you.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ),

            SizedBox(height: 31,),

            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context, "paid");
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                side: const BorderSide(
                  color: Colors.grey, // Grey border
                  width: 1.0,         // Border thickness
                ),
              ),
              child: const Text(
                "PAY AMOUNT",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16
                ),
              ),
            ),

            SizedBox(height: 41,)

          ],
        ),
      ),
    );
  }
}
