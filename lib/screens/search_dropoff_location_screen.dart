import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../manageInfo/manage_info.dart'; // Add the correct import path for ManageInfo
import '../helper/gmap_functions.dart'; // Add the correct import path for GMapFunctions
import '../map_info.dart'; // Add the correct import path for gMapKey
import '../models/predicted_places.dart'; // Add the correct import path for PredictedPlaces
import '../widgets/predicted_places_design.dart'; // Add the correct import path for PredictedPlacesDesign

class SearchDropOffLocationScreen extends StatefulWidget {
  const SearchDropOffLocationScreen({super.key});

  @override
  State<SearchDropOffLocationScreen> createState() =>
      _SearchDropOffLocationScreenState();
}

class _SearchDropOffLocationScreenState
    extends State<SearchDropOffLocationScreen> {
  //PredictedPlaces class is used to save the predicted places data from places auto complete api response and we will use this class to show the predicted places list in our app according to user input in destination search field
  //predicted_places.dart file is used to create PredictedPlaces class and also we will create a function in that class to convert the json data from places auto complete api response to PredictedPlaces object so that we can use it in our app
  List<PredictedPlaces> predictedPlacesListForDestination = [];
  TextEditingController pickUpLocController = TextEditingController();
  TextEditingController dropOffLocController = TextEditingController();

  Future<void> placesAutoCompleteSearch(String getUserInputText) async {
    //calling places auto complete api to get the predicted places list from api according to user input in destination search field when user input text changes in destination search field and we will pass user input text to that function to get the predicted places list from api according to user input in destination search field
    String textInputByUser = getUserInputText;

    //textInputByUser.length > 2 because we will call places auto complete api to get the predicted places list from api according to user input in destination search field when user input text length is greater than 2 because if we call api for every single character then it will be too much unnecessary api calls and it will also increase the cost of api calls
    if (textInputByUser.length > 2) {
      //we will call places auto complete api to get the predicted places list from api according to user input in destination search field
      //it is common api provided by google map and we just need to pass user input text and google map api key to get the response from this api
      //we need to enable places api and geocoding api in google cloud console to use this api and also we need to restrict our api key to prevent unauthorized use of our api key
      //2
      //String urlPlacesAutoCompleteAPI =
      //   "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$textInputByUser&key=$gMapKey&components=country:LK";
      String urlPlacesAutoCompleteAPI =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?"
          "input=$textInputByUser"
          "&key=$gMapKey"
          "&components=country:lk"
          "&location=6.9271,79.8612" // Colombo
          "&radius=50000";
      //country : we need to pass country code to get the predicted places list according to user input in destination search field because if we don't pass country code then it will return the predicted places list from all over the world and it will be difficult for user to find their desired place from that list and also it will increase the cost of api calls because we will get more data from api response if we don't pass country code
      //with 2 letters country code we can get the predicted places list according to user input in destination search field from that particular country and it will be easier for user to find their desired place from that list and also it will reduce the cost of api calls because we will get less data from api response if we pass country code
      var placesAPIResponseData = await GmapFunctions.requestAPI(
        urlPlacesAutoCompleteAPI,
      );
      print("DEW @@@ API RESPONSE: ");
      print("DEW @@@ API RESPONSE: $placesAPIResponseData");
      if (placesAPIResponseData == "error") {
        return;
      }

      if (placesAPIResponseData["status"] == "OK") {
        var jsonPredictedPlacesDataFromAPI =
            placesAPIResponseData["predictions"];
        var predictedPlacesDataFromAPI =
            (jsonPredictedPlacesDataFromAPI as List)
                .map(
                  (predictedPlace) => PredictedPlaces.fromJson(predictedPlace),
                )
                .toList();

        setState(() {
          predictedPlacesListForDestination = predictedPlacesDataFromAPI;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    //we will get user live location address in readable format and also we will save it in manageInfo class using provider state management which we can use it anywhere in our app
    String userPickupAddress =
        Provider.of<ManageInfo>(
          context,
          listen: false,
        ).pickUp!.userAddressInReadableFormat ??
        "";
    pickUpLocController.text = userPickupAddress;
    return Scaffold(
      backgroundColor: Colors.grey[800],
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: Container(
              height: 230,
              color: Colors.black,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  top: 46,
                  right: 16,
                  bottom: 14,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 6),
                    //pickup location
                    Row(
                      children: [
                        Image.asset(
                          "assets/images/userLocMarker.png",
                          width: 40,
                          height: 40,
                        ),
                        SizedBox(width: 18),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(2),
                              child: TextField(
                                controller: pickUpLocController,
                                enabled:
                                    false, //we will disable this text field because we just want to show user live location address here and we don't want user to edit it
                                decoration: const InputDecoration(
                                  hintText: "Pickup Address",
                                  fillColor: Colors.white12,
                                  filled: true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(
                                    left: 11,
                                    top: 9,
                                    bottom: 9,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),
                    //search drop off location
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Image.asset(
                            "assets/images/back.png",
                            width: 30,
                            height: 30,
                          ),
                        ),
                        Center(
                          child: Text(
                            "Search Drop-Off Location",
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: "MontserratBold",
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),
                    //destination search field
                    Row(
                      children: [
                        Image.asset(
                          "assets/images/destinationmark.png",
                          width: 40,
                          height: 40,
                        ),
                        SizedBox(width: 18),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(2),
                              child: TextField(
                                controller: dropOffLocController,
                                //in here we will call placesAutoCompleteSearch function to get
                                //the predicted places list from places auto complete api
                                //according to user input in destination search field when
                                //user input text changes in destination search field and we
                                //will pass user input text to that function to get the predicted
                                //places list from api according to user input in destination search field
                                onChanged: (getUserInputText) =>
                                    placesAutoCompleteSearch(getUserInputText),
                                decoration: const InputDecoration(
                                  hintText: "search here...",
                                  fillColor: Colors.white12,
                                  filled: true,
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.only(
                                    left: 11,
                                    top: 9,
                                    bottom: 9,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 12),

          predictedPlacesListForDestination.isNotEmpty
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/images/choose.png",
                      width: 50,
                      height: 50,
                    ),
                    SizedBox(width: 5),
                    Center(
                      child: Text(
                        "Choose",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : Container(),

          SizedBox(height: 12),

          if (predictedPlacesListForDestination.isNotEmpty)
            //... means we will show the predicted places list in our app according to user input in destination
            //search field and we will use predicted_places_design.dart file to design each item of the predicted
            //places list and we will pass each predicted place data to that file to show the predicted place name and
            //address in our app and also we will use card widget to show the predicted place name and address in a card
            //and we will also add on tap event to each card to get the place details of the selected predicted  place and we will save the place details in manageInfo class using provider state management which we can use it anywhere in our app and also we will pop the search drop off location screen after selecting the destination from the predicted places list
            ...predictedPlacesListForDestination.map((prediction) {
              return Card(
                color: Colors.black,
                //predicted_places_design.dart file is used to design each item of the
                //predicted places list and we will pass each predicted place data to that
                //file to show the predicted place name and address in our app and also
                // we will use card widget to show the predicted place name and address in a
                //card and we will also add on tap event to each card to get the place details
                //of the selected predicted  place and we will save the place details in manageInfo
                //class using provider state management which we can use it anywhere in our app and also
                // we will pop the search drop off location screen after selecting the destination from
                //the predicted places list
                child: PredictedPlacesDesign(predictedPlace: prediction),
              );
            }),
        ],
      ),
    );
  }
}
