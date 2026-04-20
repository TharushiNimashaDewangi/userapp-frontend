import 'package:flutter/material.dart';
import '../models/predicted_places.dart'; // Add the correct import path for PredictedPlaces
import 'loading_dialog.dart'; // Import the LoadingDialog widget
import '../helper/gmap_functions.dart'; // Import GMapFunctions
import '../manageInfo/manage_info.dart'; // Import ManageInfo class
import '../map_info.dart'; // Import gMapKey
import '../models/address.dart'; // Import Address model
import 'package:provider/provider.dart'; // Import Provider for state management

class PredictedPlacesDesign extends StatefulWidget {
  PredictedPlaces predictedPlace;
  PredictedPlacesDesign({super.key, required this.predictedPlace});

  @override
  State<PredictedPlacesDesign> createState() => _PredictedPlacesDesignState();
}

class _PredictedPlacesDesignState extends State<PredictedPlacesDesign> {
  Future<void> retrievePlaceDetails(String destinationPlaceID) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(),
    );
    print(" dewwwwwww@@@@@@@destinationPlaceID:"); //
    print(" dewwwwwww@@@@@@@destinationPlaceID: $destinationPlaceID"); // 👈 ADD
    //get place details for the selected destination
    ///4
    String placeDetailsAPIUrl =
        "https://maps.googleapis.com/maps/api/place/details/json?place_id=$destinationPlaceID&key=$gMapKey";
    var placeDetailsAPIResponseData = await GmapFunctions.requestAPI(
      placeDetailsAPIUrl,
    );

    Navigator.pop(context);

    if (placeDetailsAPIResponseData == "error") {
      return;
    }

    if (placeDetailsAPIResponseData["status"] == "OK") {
      Address address = Address();
      address.placeName = placeDetailsAPIResponseData["result"]["name"];
      address.latPosition =
          placeDetailsAPIResponseData["result"]["geometry"]["location"]["lat"];
      address.lngPosition =
          placeDetailsAPIResponseData["result"]["geometry"]["location"]["lng"];
      address.placeID = destinationPlaceID;
      print(" dewwwwwww@@@@@@@placeName:111r"); //
      print(
        " dewwwwwww@@@@@@@destinationPlaceID: address.placeName..toString()",
      );
      //fixed the issue of destination place name not showing in the destination text field after selecting the predicted place from the list by updating the destination drop off address in the manageInfo class using provider state management
      Provider.of<ManageInfo>(context, listen: false).updateDestinationDropOffAddress(address);
      print(" dewwwwwww@@@@@@@popup:"); //
      Navigator.pop(context, "destinationSelected");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        retrievePlaceDetails(widget.predictedPlace.placeID.toString());
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
      child: Column(
        children: [
          SizedBox(height: 12),

          Row(
            children: [
              Image.asset("assets/images/search.png", width: 35, height: 35),

              SizedBox(width: 13),
              //expanded widget is used to avoid text overflow error when the predicted place name is too long to fit in one line
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      // Display the main text of the predicted place
                      widget.predictedPlace.mainText.toString(),
                      // Handle text overflow
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),

                    SizedBox(height: 3),

                    Text(
                      widget.predictedPlace.secondaryText.toString(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 12),
        ],
      ),
    );
  }
}
