import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:user_app_frontend/mapStyleCustom.dart';
import 'package:user_app_frontend/map_info.dart';
import 'package:user_app_frontend/widgets/trip_payment_dialog.dart';
// TODO: Replace the import path below with the actual path to your UserDrawer widget file.
import 'package:user_app_frontend/widgets/user_drawer.dart';
import 'package:user_app_frontend/helper/helper_functions.dart';
import 'package:provider/provider.dart';
import 'package:user_app_frontend/manageInfo/manage_info.dart'; // Import ManageInfo class
import 'package:user_app_frontend/helper/gmap_functions.dart'; // Import GMapFunctions
import 'package:user_app_frontend/screens/search_dropoff_location_screen.dart'; // Import SearchDropOffLocationScreen
import 'package:user_app_frontend/widgets/loading_dialog.dart'; // Import LoadingDialog widget
import 'package:user_app_frontend/models/direction_details.dart'; // Import DirectionDetails model
import 'package:user_app_frontend/models/nearest_online_drivers.dart';
import 'package:user_app_frontend/driver/driver_functions.dart'; // Import DriverFunctions class
import 'package:loading_animation_widget/loading_animation_widget.dart'; // Import LoadingAnimationWidget
import 'package:restart_app/restart_app.dart'; // Import Restart class
import '../driver_info.dart'; // Import driver_info.dart for driver details variables section15
import '../user_info.dart'; // Import user_info.dart for user details variables section15
import 'package:user_app_frontend/widgets/snackbar.dart'; // Import custom Snackbar widget
import 'package:user_app_frontend/pushNotificationSystem/push_notification_system.dart'; // Import PushNotificationSystem class for sending notifications to drivers when user request a ride

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //section 15 for handling nearest online drivers around user location within radius 15 and also listen to that query in real time for any changes in driver location or driver online offline status and accordingly update the nearest online drivers list and markers on map
  String appState = "normal";

  Set<Circle> cSet = {};
  BitmapDescriptor? carIconForNearestDriver;
  double carTypeContainerHeight = 0;
  final Completer<GoogleMapController> controllerGMapCompleter =
      Completer<GoogleMapController>();

  GoogleMapController? controllerGMapInstance;
  BitmapDescriptor? customUserLocationIcon;
  DirectionDetails? directionDetailsForTrip;
  //For drawer open close state handling and accordingly show hide user live location container and car type container
  bool drawerOpened =
      true; //for handling drawer open close state and accordingly show hide user live location container and car type container

  HelperFunctions helperFunctions = HelperFunctions();
  bool isDirectionDetailsInfoRequested = false;
  //Marker? userLocationMarker;

  //function for fetching user live location and updating on map -> updateUserMarkerOnMap
  Set<Marker> markerSet = {};

  List<NearestOnlineDrivers>? nearestOnlineDriversList;
  //for handling nearest online drivers around user
  //location within radius 15 and also listen to that
  //query in real time for any changes in driver location
  //or driver online offline status and accordingly update
  //the nearest online drivers list and markers on map
  bool onlineNearestDriversKeysLoaded = false;

  Set<Polyline> pSet = {};
  double paddingFromBottomGMap = 0;
  //double tripDetailsConstainerHeight = 0;

  //DirectionDetails? directionDetailsForTrip;
  List<LatLng> polylineLatLng = [];

  //section15 for handling nearest online drivers around user location within radius 15 and also listen to that query in real time for any changes in driver location or driver online offline status and accordingly update the nearest online drivers list and markers on map
  DatabaseReference? rideRequestReference;

  StreamSubscription? rideStatusListener;
  //for handling drawer open close state and accordingly show hide user live location container and car type container
  GlobalKey<ScaffoldState> scaffoldStateKey = GlobalKey<ScaffoldState>();

  Timer? timeoutTimer;
  double tripAcceptedDetailsContainerHeight =
      0; //section 15 for handling nearest online drivers around user location within radius 15 and also listen to that query in real time for any changes in driver location or driver online offline status and accordingly update the nearest online drivers list and markers on map

  Position? userLivePosition; //geolocator package
  double userLocationContainerHeight =
      200; //we will show user live location container when drawer is closed and hide it when drawer is open and we will do opposite for car type container

  double waitingForRideContainerHeight =
      0; //section15 for handling nearest online drivers around user location within radius 15 and also listen to that query in real time for any changes in driver location or driver online offline status and accordingly update the nearest online drivers list and markers on map

  @override
  void initState() {
    super.initState();
    loadCustomUserLocationIcon();
    loadCustomNearestDriverLocationIcon(); //load custom marker icon for nearest online drivers around user location within radius 15
    helperFunctions.retrieveUserData(context);
  }

  //function for fetching user live location and updating on map
  void loadCustomUserLocationIcon() {
    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/images/userLocMarker.png",
    ).then((icon) {
      customUserLocationIcon = icon;
    });
  }

  //for handling nearest online drivers around user location within radius 15 and also listen to that query in real time for any changes in driver location or driver online offline status and accordingly update the nearest online drivers list and markers on map
  void loadCustomNearestDriverLocationIcon() {
    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/images/tracking.png",
    ).then((icon) {
      carIconForNearestDriver = icon;
    });
  }

  //function for updating user live location marker on map
  void updateUserMarkerOnMap() {
    LatLng userLatLng = LatLng(
      userLivePosition!.latitude,
      userLivePosition!.longitude,
    );

    if (!markerSet.any((m) => m.markerId.value == "userLocation")) {
      markerSet.add(
        Marker(
          markerId: MarkerId("userLocation"),
          position: userLatLng,
          icon: customUserLocationIcon ?? BitmapDescriptor.defaultMarker,
        ),
      );

      // If the marker already exists, update its position in the UI
      setState(() {});
    }
  }

  //function for fetching user live location and updating on map
  Future<void> obtainUserLivePosition() async {
    //permission handling for location

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      print("❌ Permission denied again.");
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      print(
        "🚫 Permission permanently denied. Ask user to enable it from Settings.",
      );
      await Geolocator.openAppSettings();
      return;
    }
    Position userCurrentPosition = await Geolocator.getCurrentPosition();
    userLivePosition = userCurrentPosition;

    //update user location marker on map
    LatLng latLngUserPosition = LatLng(
      userLivePosition!.latitude,
      userLivePosition!.longitude,
    );
    //in case live location not fetch then fetch default location from map_info.dart
    CameraPosition cp = CameraPosition(target: latLngUserPosition, zoom: 16);
    //aniamte camera to user live location
    controllerGMapInstance!.animateCamera(CameraUpdate.newCameraPosition(cp));

    //this implemetation is in gmap_functions.dart file but we want to call this function here because we want to fetch user live location address and show it in user location container at bottom of the screen
    await GmapFunctions.getHumanReadableAddressFromGeoGraphicCoOrdinates(
      userLivePosition!,
      context,
    ); //end of this function we will get user live location address in readable format and also we will save it in manageInfo class using provider state management which we can use it anywhere in our app
    updateUserMarkerOnMap();

    await startGeoFireListener();
  }

  //setState to show car type details container
  void carTypeDetailsContainer() {
    setState(() {
      userLocationContainerHeight = 0;
      carTypeContainerHeight = 266;
      drawerOpened = false;
    });
    fetchTripDirectionDetailsFromPickUpToDestination();
  }

  Future<void> fetchTripDirectionDetailsFromPickUpToDestination() async {
    //pickUp and dropOffDestination are from manageInfo class using provider
    //state management which we have set in search_dropoff_location_screen.dart
    //file when user select the destination from search place screen
    var pickUp = Provider.of<ManageInfo>(context, listen: false).pickUp;
    //dropOffDestination is from manageInfo class using provider state management
    // which we have set in search_dropoff_location_screen.dart file when user
    //select the destination from search place screen
    var dropOffDestination = Provider.of<ManageInfo>(
      context,
      listen: false,
    ).destinationDropOff;
    //var dropOffDestination = Provider.of<ManageInfo>(context).destinationDropOff;
    print("pickup@@@@@@@@@@@@@@@@@@@@ = $pickUp");
    //we will fetch direction details from google map direction API using helper
    //function which we have created in gmap_functions.dart file and we will pass
    //pickup and dropoff location latlng to that function and it will return us
    //the direction details for that trip
    var pickupLatLng = LatLng(pickUp!.latPosition!, pickUp.lngPosition!);
    //dropOffDestinationLatLng is the latlng for drop off destination which
    //we have selected from search place screen and we have set that destination
    //latlng in manageInfo class using provider state management
    //in search_dropoff_location_screen.dart file when user select
    // the destination from search place screen
    var dropOffDestinationLatLng = LatLng(
      dropOffDestination!.latPosition!,
      dropOffDestination.lngPosition!,
    );
    print("pickup@@@@@@@@@@@@@@@@@@@@ = $dropOffDestinationLatLng");
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(),
    );

    //fetching direction details for the trip from pickup location to drop off
    //destination location using google map direction api and helper function
    // which we have created in gmap_functions.dart file
    var directionDetailsFromAPI =
        await GmapFunctions.fetchDirectionDetailsFromAPI(
          pickupLatLng,
          dropOffDestinationLatLng,
        );
    setState(() {
      directionDetailsForTrip = directionDetailsFromAPI;
    });

    Navigator.pop(context);
    //PolylinePoints ->i mport   flutter_polyline_points: to puspec.yaml and then we can use that package to decode the encoded polyline points which we will get from google map direction api and then we will draw the route on map using those decoded polyline points
    PolylinePoints polylinePoints = PolylinePoints();
    //getting list of decoded polyline points which we will get from
    //google map direction api and then we will draw the route on map
    // using those decoded polyline points
    List<PointLatLng> latLngPolylinePoints = polylinePoints.decodePolyline(
      directionDetailsForTrip!.encodedPointsForDrawingRoutes!,
    );

    //after getting the list of decoded polyline points we will
    //convert that list of decoded polyline points to list of latlng
    //which we will use to draw the route on map using those latlng points
    polylineLatLng.clear();
    if (latLngPolylinePoints.isNotEmpty) {
      for (var point in latLngPolylinePoints) {
        polylineLatLng.add(LatLng(point.latitude, point.longitude));
      }
    }

    print("polylineLatLng = $polylineLatLng");
    //polyline is the line which we will draw on map to show the route
    //from pickup location to drop off destination location and for
    //that we need to create polyline object and then we will add
    //that polyline object to set of polylines which we will show
    //on map and for creating polyline object we need to pass the
    //list of latlng points which we will get from decoding the
    //encoded polyline points which we will get from google map
    //direction api and then we will draw the route on map using
    //those latlng points
    pSet.clear();
    setState(() {
      Polyline pLine = Polyline(
        polylineId: const PolylineId("pID"),
        color: Colors
            .white, //to change the color of the route line on map we can change the color property of polyline object and then we will add that polyline object to set of polylines which we will show on map
        points:
            polylineLatLng, //list of latlng points which we will get from decoding the encoded polyline points which we will get from google map direction api and then we will draw the route on map using those latlng points
        jointType: JointType.round,
        width: 3,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      pSet.add(
        pLine,
      ); //add the polyline object to set of polylines which we will show on map
    });

    //it will make sure that polyline is fit to the map
    LatLngBounds boundsLatLng;
    if (pickupLatLng.latitude > dropOffDestinationLatLng.latitude &&
        pickupLatLng.longitude > dropOffDestinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: dropOffDestinationLatLng,
        northeast: pickupLatLng,
      );
    } else if (pickupLatLng.longitude > dropOffDestinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(
          pickupLatLng.latitude,
          dropOffDestinationLatLng.longitude,
        ),
        northeast: LatLng(
          dropOffDestinationLatLng.latitude,
          pickupLatLng.longitude,
        ),
      );
    } else if (pickupLatLng.latitude > dropOffDestinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(
          dropOffDestinationLatLng.latitude,
          pickupLatLng.longitude,
        ),
        northeast: LatLng(
          pickupLatLng.latitude,
          dropOffDestinationLatLng.longitude,
        ),
      );
    } else {
      boundsLatLng = LatLngBounds(
        southwest: pickupLatLng,
        northeast: dropOffDestinationLatLng,
      );
    }
    //animate camera to fit the polyline in map and for that we will use the
    // bounds of the polyline which we will get from the pickup location
    controllerGMapInstance!.animateCamera(
      CameraUpdate.newLatLngBounds(boundsLatLng, 72),
    );
    //after getting the bounds of the polyline we will draw the route on map
    // using those bounds and then we will add marker for pickup location and
    //drop off destination location on map using those bounds
    Marker markerPickUpPoint = Marker(
      markerId: const MarkerId("ppMarkerID"),
      position: pickupLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      ), //to change the color of the marker on map we can change the hue property of BitmapDescriptor.defaultMarkerWithHue and then we will add that marker object to set of markers which we will show on map
      infoWindow: InfoWindow(
        title: pickUp.placeName,
        snippet: "Pickup Point",
      ), //to show the info window on marker click we can pass the title and snippet property in infoWindow property of marker object and then we will add that marker object to set of markers which we will show on map
    );
    //drop off destination marker
    Marker markerDropOffDestinationPoint = Marker(
      markerId: const MarkerId("dpMarkerID"),
      position: dropOffDestinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: dropOffDestination.placeName,
        snippet: "Destination Point",
      ),
    );
    //set of markers which we will show on map and for that we will add the
    //marker object to set of markers which we will show on map and then
    //we will call setState to update the UI and show the marker on map
    setState(() {
      markerSet.add(markerPickUpPoint);
      markerSet.add(markerDropOffDestinationPoint);
    });
    //after adding marker for pickup location and drop off destination location
    //on map using those bounds we will add circle for pickup location and drop
    //off destination location on map using those bounds
    Circle circlePP = Circle(
      circleId: const CircleId('pCircleID'),
      strokeColor: Colors.blue,
      strokeWidth: 2,
      radius: 6,
      center: pickupLatLng,

      ///adding circle for pickup location on map using those bounds
      fillColor: Colors.white,
    );

    Circle circleDP = Circle(
      circleId: const CircleId('dCircleID'),
      strokeColor: Colors.blue,
      strokeWidth: 2,
      radius: 6,
      center:
          dropOffDestinationLatLng, //adding circle for drop off destination location on map using those bounds
      fillColor: Colors.white,
    );
    //set of circles which we will show on map and for that we will add
    //the circle object to set of circles which we will show on map and
    //then we will call setState to update the UI and show the circle on map
    setState(() {
      cSet.add(circlePP);
      cSet.add(circleDP);
    });
  }

  startGeoFireListener() {
    Geofire.initialize("liveDrivers");
    //for fetching the nearest online drivers around user live
    //location within radius 15 and also listen to that query in
    //real time for any changes in driver location or driver online
    // offline status and accordingly update the nearest online
    //drivers list and markers on map
    Geofire.queryAtLocation(
      userLivePosition!.latitude,
      userLivePosition!.longitude,
      15,
    )!.listen((driver) {
      if (driver != null) {
        var liveDriverInfo = driver["callBack"];

        switch (liveDriverInfo) {
          //within radius 15 around user Location when any driver is online or become online
          case Geofire.onKeyEntered:
            NearestOnlineDrivers onlineDriver = NearestOnlineDrivers();
            onlineDriver.driverKey = driver["key"];
            onlineDriver.driverLatitude = driver["latitude"];
            onlineDriver.driverLongitude = driver["longitude"];
            DriverFunctions.nearestOnlineDriversList.add(onlineDriver);
            if (onlineNearestDriversKeysLoaded == true) {
              //update the nearest online drivers list and markers
              // on map in real time when any driver is moving around
              //user location within radius 15 or when any driver
              //go outside from radius 15 around user location or
              //when any driver become online or become offline
              updateNearestOnlineDriverMarkerOnGoogleMap();
            }
            break;

          //when any driver go outside from radius 15 around
          //user Location / when any driver become offline
          case Geofire.onKeyExited:
            DriverFunctions.deleteDriverFromList(driver["key"]);
            updateNearestOnlineDriverMarkerOnGoogleMap();
            break;

          //when any driver is moving around user location within radius 15
          case Geofire.onKeyMoved:
            NearestOnlineDrivers onlineDriver = NearestOnlineDrivers();
            onlineDriver.driverKey = driver["key"];
            onlineDriver.driverLatitude = driver["latitude"];
            onlineDriver.driverLongitude = driver["longitude"];
            DriverFunctions.updateNearestOnlineDriversLocation(onlineDriver);
            updateNearestOnlineDriverMarkerOnGoogleMap();
            break;
          //when we start the geofire listener then
          //it will give us the list of all online drivers
          //around user location within radius 15 and after
          //that it will give us real time updates about any
          // changes in driver location or driver online offline
          //status and accordingly we will update the nearest online
          //drivers list and markers on map
          case Geofire.onGeoQueryReady:
            onlineNearestDriversKeysLoaded = true;
            updateNearestOnlineDriverMarkerOnGoogleMap();
            break;
        }

        updateUserMarkerOnMap();
      }
    });
  }

  updateNearestOnlineDriverMarkerOnGoogleMap() {
    setState(() {
      markerSet.clear();
    });
    //in here we will update the nearest online drivers list
    //and markers on map in real time when any driver
    //is moving around user location within radius
    //15 or when any driver go outside from radius
    //15 around user location or when any driver
    //become online or become offline
    Set<Marker> tempMarkerSet = Set<Marker>();
    for (NearestOnlineDrivers nearestOnlineDriver
        in DriverFunctions.nearestOnlineDriversList) {
      LatLng driverCurrentPosition = LatLng(
        nearestOnlineDriver.driverLatitude!,
        nearestOnlineDriver.driverLongitude!,
      );

      Marker driverMarker = Marker(
        markerId: MarkerId(
          "driverKey = " + nearestOnlineDriver.driverKey.toString(),
        ),
        position: driverCurrentPosition,
        icon: carIconForNearestDriver!,
      );

      tempMarkerSet.add(driverMarker);
    }

    setState(() {
      markerSet = tempMarkerSet;
    });
  }

  //section15 for handling nearest online drivers around user location within radius 15 and also listen to that query in real time for any changes in driver location or driver online offline status and accordingly update the nearest online drivers list and markers on map
  showWaitingContainer(fareAmount) {
    setState(() {
      carTypeContainerHeight = 0;
      waitingForRideContainerHeight = 210;
      drawerOpened = true;
    });

    storeRideRequestDataToDatabase(fareAmount);
  }

  //section15 for handling nearest online drivers around user location within radius 15 and also listen to that query in real time for any changes in driver location or driver online offline status and accordingly update the nearest online drivers list and markers on map
  storeRideRequestDataToDatabase(fareAmount) {
    rideRequestReference = FirebaseDatabase.instance
        .ref()
        .child("rideRequests")
        .push();
    String? rideRequestID = rideRequestReference!.key;

    var pickUp = Provider.of<ManageInfo>(context, listen: false).pickUp;
    var dropOffDestination = Provider.of<ManageInfo>(
      context,
      listen: false,
    ).destinationDropOff;

    Map userPickUpLatLng = {
      "latitude": pickUp!.latPosition.toString(),
      "longitude": pickUp.lngPosition.toString(),
    };

    Map userDropOffLatLng = {
      "latitude": dropOffDestination!.latPosition.toString(),
      "longitude": dropOffDestination.lngPosition.toString(),
    };

    Map driverLatLng = {"latitude": "", "longitude": ""};
    //for saveing ride request data to firebase realtime database in rideRequests node and we will create a unique id for each ride request using push() method and then we will save that unique id in rideRequestID variable and then we will save that unique id in the ride request data map which we will save in firebase realtime database and then we will use that unique id to update the ride request data in firebase realtime database when driver accept the trip request and also we will use that unique id to listen to the changes in that ride request data in firebase realtime database when driver accept the trip request and accordingly we will update the UI of our app
    Map rideRequestInfoMap = {
      "tripID": rideRequestID,
      "publishDateTime": DateTime.now().toString(),

      "userName": nameOfUser,
      "userPhone": phoneOfUser,
      "userID": FirebaseAuth.instance.currentUser!.uid,

      "pickUpLatLng": userPickUpLatLng,
      "dropOffLatLng": userDropOffLatLng,

      "pickUpAddress": pickUp.placeName,
      "dropOffAddress": dropOffDestination.placeName,

      "driverID": "waiting",
      "carDetails": "",
      "driverLocation": driverLatLng,
      "driverName": "",
      "driverPhone": "",

      "fareAmount": fareAmount,
      "status": "new",
    };
    //section15: storing ride request data to firebase realtime database in rideRequests node and we will create a unique id for each ride request using push() method and then we will save that unique id in rideRequestID variable and then we will save that unique id in the ride request data map which we will save in firebase realtime database and then we will use that unique id to update the ride request data in firebase realtime database when driver accept the trip request and also we will use that unique id to listen to the changes in that ride request data in firebase realtime database when driver accept the trip request and accordingly we will update the UI of our app
    rideRequestReference!.set(rideRequestInfoMap);

    rideStatusListener = rideRequestReference!.onValue.listen((
      eventDataSnap,
    ) async {
      if (eventDataSnap.snapshot.value == null) {
        return;
      }

      if ((eventDataSnap.snapshot.value as Map)["carDetails"] != null) {
        driverCarDetails = (eventDataSnap.snapshot.value as Map)["carDetails"];
      }

      if ((eventDataSnap.snapshot.value as Map)["status"] != null) {
        status = (eventDataSnap.snapshot.value as Map)["status"];
      }

      if ((eventDataSnap.snapshot.value as Map)["driverName"] != null) {
        driverName = (eventDataSnap.snapshot.value as Map)["driverName"];
      }

      if ((eventDataSnap.snapshot.value as Map)["driverPhone"] != null) {
        driverPhoneNumber =
            (eventDataSnap.snapshot.value as Map)["driverPhone"];
      }

      if ((eventDataSnap.snapshot.value as Map)["driverLocation"] != null) {
        double driverLat = double.parse(
          (eventDataSnap.snapshot.value as Map)["driverLocation"]["latitude"]
              .toString(),
        );
        double driverLng = double.parse(
          (eventDataSnap.snapshot.value as Map)["driverLocation"]["longitude"]
              .toString(),
        );
        LatLng driverCurrentPositionLatLng = LatLng(driverLat, driverLng);

        if (status == "accepted") {
          getUpdatedTripInfoFromDriverCurrentPositionToUserPickup(
            driverCurrentPositionLatLng,
          );
        } else if (status == "arrived") {
          setState(() {
            displayTripStatus = "Hey! Your driver just arrived.";
          });
        } else if (status == "ontrip") {
          getUpdatedTripInfoFromDriverCurrentPositionToUserDestination(
            driverCurrentPositionLatLng,
          );
        }
      }

      if (status == "accepted") {
        showRideDetailsContainer();

        Geofire.stopListener();

        setState(() {
          markerSet.removeWhere(
            (element) => element.markerId.value.contains("driverKey"),
          );
        });
      }

      if (status == "ended") {
        if ((eventDataSnap.snapshot.value as Map)["fareAmount"] != null) {
          DatabaseEvent fareAmountRef = await FirebaseDatabase.instance
              .ref()
              .child("rideRequests")
              .child(rideRequestID!)
              .child("fareAmount")
              .once();
          var fareAmount = fareAmountRef.snapshot.value;

          var paymentDialogRes = await showDialog(
            context: context,
            builder: (BuildContext context) => TripPaymentDialog(
              totalFareAmount: fareAmount.toString(),
              carTypeChecker: driverCarTypeRetrieved,
            ),
          );

          if (paymentDialogRes == "paid") {
            rideRequestReference!.onDisconnect();
            rideRequestReference = null;

            rideStatusListener!.cancel();
            rideStatusListener = null;

            clearGoogleMap();

            Restart.restartApp();
          }
        }
      }
    });
  }

  getUpdatedTripInfoFromDriverCurrentPositionToUserPickup(
    driverCurrentPositionLatLng,
  ) async {
    if (!isDirectionDetailsInfoRequested) {
      isDirectionDetailsInfoRequested = true;

      var userPickUpPositionLatLng = LatLng(
        userLivePosition!.latitude,
        userLivePosition!.longitude,
      );

      var directionDetailsInfoForPickup =
          await GmapFunctions.fetchDirectionDetailsFromAPI(
            driverCurrentPositionLatLng,
            userPickUpPositionLatLng,
          );

      if (directionDetailsInfoForPickup == null) {
        return;
      }

      setState(() {
        displayTripStatus =
            "Driver will Arrive in ${directionDetailsInfoForPickup.duration}";
      });

      isDirectionDetailsInfoRequested = false;
    }
  }

  getUpdatedTripInfoFromDriverCurrentPositionToUserDestination(
    driverCurrentPositionLatLng,
  ) async {
    if (!isDirectionDetailsInfoRequested) {
      isDirectionDetailsInfoRequested = true;

      var dropOffPosition = Provider.of<ManageInfo>(
        context,
        listen: false,
      ).destinationDropOff;
      var userDropOfPositionLatLng = LatLng(
        dropOffPosition!.latPosition!,
        dropOffPosition.lngPosition!,
      );

      var directionDetailsInfoForDropOff =
          await GmapFunctions.fetchDirectionDetailsFromAPI(
            driverCurrentPositionLatLng,
            userDropOfPositionLatLng,
          );

      if (directionDetailsInfoForDropOff == null) {
        return;
      }

      setState(() {
        displayTripStatus =
            "Dropping you off in ${directionDetailsInfoForDropOff.duration}";
      });

      isDirectionDetailsInfoRequested = false;
    }
  }

  showRideDetailsContainer() {
    setState(() {
      carTypeContainerHeight = 0;
      waitingForRideContainerHeight = 0;
      tripAcceptedDetailsContainerHeight = 201;
    });
  }

  clearGoogleMap() {
    setState(() {
      polylineLatLng.clear();
      pSet.clear();
      markerSet.clear();
      cSet.clear();
      userLocationContainerHeight = 200;
      carTypeContainerHeight = 0;
      waitingForRideContainerHeight = 0;
      tripAcceptedDetailsContainerHeight = 0;
      drawerOpened = true;

      driverName = "";
      driverPhoneNumber = "";
      driverCarDetails = "";

      status = "";
      displayTripStatus = "Driver will Arrive soon";
    });
  }

  deleteRideRequest() {
    rideRequestReference!.remove();

    timeoutTimer!.cancel();
    rideStatusListener!.cancel();

    setState(() {
      appState = "normal";
    });
  }

  findDriverBasedOnCarType(String carTypeUserRequested) async {
    if (nearestOnlineDriversList == null || nearestOnlineDriversList!.isEmpty) {
      displaySnackBar("No Driver Found. Try Again later.", context);
      deleteRideRequest();
      clearGoogleMap();

      Restart.restartApp();

      return;
    }
    while (nearestOnlineDriversList!.isNotEmpty) {
      var pickADriverFromList = nearestOnlineDriversList![0];
      driverCarTypeRetrieved = "";

      DatabaseReference reference = FirebaseDatabase.instance
          .ref()
          .child("allDrivers")
          .child(pickADriverFromList.driverKey.toString());

      DataSnapshot snapshot = await reference.get();
      final dataMap = snapshot.value as Map?;

      if (dataMap != null && dataMap["carType"] != null) {
        driverCarTypeRetrieved = dataMap["carType"];
      }

      if (driverCarTypeRetrieved == carTypeUserRequested) {
        // Send push notification to this driver and stop searching.
        sendPushNotificationToDriver(pickADriverFromList, carTypeUserRequested);
        return;
      }

      // If not matched, remove and search next driver
      nearestOnlineDriversList!.removeAt(0);
    }
    /*
    if (nearestOnlineDriversList!.isEmpty) {
      deleteRideRequest();
      clearGoogleMap();
      displaySnackBar("No Driver Found. Try Again later.", context);

      Restart.restartApp();

      return;
    }

    findDriverBasedOnCarType(carTypeUserRequested); // recursive call
  */
    // All drivers checked, no match found
    displaySnackBar("No Driver Found. Try Again later.", context);
    deleteRideRequest();
    clearGoogleMap();
    Restart.restartApp();
  }

  sendPushNotificationToDriver(
    NearestOnlineDrivers driverPicked,
    String carTypeUserRequested,
  ) {
    DatabaseReference pickedDriverRef = FirebaseDatabase.instance
        .ref()
        .child("allDrivers")
        .child(driverPicked.driverKey.toString())
        .child("newRideStatus");

    // Assign ride ID
    pickedDriverRef.set(rideRequestReference!.key);

    ///SEND PUSH NOTIFICATION CODE
    DatabaseReference fcmTokenRef = FirebaseDatabase.instance
        .ref()
        .child("allDrivers")
        .child(driverPicked.driverKey.toString())
        .child("fcmToken");

    fcmTokenRef.once().then((infoSnapshot) {
      if (infoSnapshot.snapshot.value != null) {
        String fcmDeviceRecognitionToken = infoSnapshot.snapshot.value
            .toString();

        PushNotificationSystem.sendNotificationToChosenDriver(
          fcmDeviceRecognitionToken,
          context,
          rideRequestReference!.key.toString(),
        );
      } else {
        return;
      }

      //Start ride status listener
      //accepted, cancelled, timeout
      rideStatusListener = pickedDriverRef.onValue.listen((snap) {
        if (snap.snapshot.value.toString() == "accepted") {
          timeoutTimer?.cancel();
          driverRequestTimeout = 25;
          rideStatusListener?.cancel();
        }
      });

      // Start timeout countdown
      timeoutTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        driverRequestTimeout -= 1;

        if (appState != "requesting") {
          timer.cancel();
          rideStatusListener?.cancel();
          pickedDriverRef.set("cancelled");
          driverRequestTimeout = 25;
        }

        if (driverRequestTimeout == 0) {
          timer.cancel();
          rideStatusListener?.cancel();
          pickedDriverRef.set("timeout");
          driverRequestTimeout = 25;

          // Remove picked driver from list and find next driver
          nearestOnlineDriversList!.remove(driverPicked);

          if (nearestOnlineDriversList!.isEmpty) {
            deleteRideRequest();
            clearGoogleMap();
            displaySnackBar("No Driver Found. Try Again later.", context);

            Restart.restartApp();

            return;
          }

          findDriverBasedOnCarType(carTypeUserRequested);
        }
      });
    });
  }

  //UI part start from here

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldStateKey,
      drawer: UserDrawer(),
      body: Stack(
        children: [
          //GOOGLE MAP
          GoogleMap(
            padding: EdgeInsets.only(top: 27, bottom: paddingFromBottomGMap),
            mapType: MapType.normal,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            markers: markerSet, //set of markers to show on map
            polylines:
                pSet, //set of polylines to show on map which we will get from decoding the encoded polyline points which we will get from google map direction api and then we will draw the route on map using those latlng points
            circles: cSet,
            initialCameraPosition: defaultLocation, //from map_info.dart
            style: mapStyleCustom, // from mapStyleCustom.dart
            onMapCreated: (GoogleMapController mapControllerGoogle) {
              controllerGMapInstance = mapControllerGoogle;
              controllerGMapCompleter.complete(controllerGMapInstance);

              setState(() {
                paddingFromBottomGMap = 302;
              });

              obtainUserLivePosition();
            },
          ),

          ///DRAWER ICON BUTTON
          Positioned(
            top: 38,
            left: 21,
            child: GestureDetector(
              onTap: () {
                if (drawerOpened == true) {
                  scaffoldStateKey.currentState!.openDrawer();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey,
                      blurRadius: 6,
                      spreadRadius: 0.6,
                      offset: Offset(0.72, 0.72),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: 21,
                  child: Icon(
                    color: Colors.white,
                    drawerOpened == true ? Icons.settings : Icons.close,
                  ),
                ),
              ),
            ),
          ),

          ///USER LOCATION CONTAINER if drawer is closed and car type container if drawer is open
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: userLocationContainerHeight,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(19),
                  topLeft: Radius.circular(19),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 11.0),

                    const Divider(height: 1, thickness: 1, color: Colors.grey),

                    const SizedBox(height: 17.0),

                    Row(
                      children: [
                        const Icon(
                          Icons.location_history,
                          color: Colors.white,
                          size: 20,
                        ),

                        const SizedBox(width: 12.0),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "My Live Location:",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                Provider.of<ManageInfo>(
                                          context,
                                          listen: false,
                                        ).pickUp ==
                                        null
                                    ? "fetching..."
                                    : Provider.of<ManageInfo>(
                                            context,
                                            listen: false,
                                          ).pickUp!.placeName ??
                                          "",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow
                                    .ellipsis, //if address is too long then it will show ... at the end of the text
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 17.0),

                    const Divider(height: 1, thickness: 1, color: Colors.grey),

                    const SizedBox(height: 17.0),

                    ElevatedButton(
                      onPressed: () async {
                        // Navigate to the drop-off location search screen
                        var dropOffLocResponse = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => SearchDropOffLocationScreen(),
                          ),
                        );

                        if (dropOffLocResponse == "destinationSelected") {
                          carTypeDetailsContainer();
                          //showTripDetailsContainer();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey, width: 1.0),
                      ),
                      child: const Text(
                        "Ready to Go?",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          //SELECT Car Type CONTAINER - trip details container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: carTypeContainerHeight,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white12,
                    blurRadius: 14.0,
                    spreadRadius: 0.4,
                    offset: Offset(.8, .8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Container(
                            width: 1,
                            height: 60,
                            color: Colors.grey.shade400,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),

                          ///CARX
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                appState = "requesting";
                              });
                              //section15 for handling nearest online drivers around user location within radius 15 and also listen to that query in real time for any changes in driver location or driver online offline status and accordingly update the nearest online drivers list and markers on map
                              showWaitingContainer(
                                helperFunctions.fareAmountCalculation(
                                  directionDetailsForTrip!,
                                  "CarX",
                                ),
                              );

                              nearestOnlineDriversList =
                                  DriverFunctions.nearestOnlineDriversList;

                              findDriverBasedOnCarType("CarX");
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 50,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: AssetImage(
                                        "assets/images/uberx.png",
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                Text(
                                  "CarX",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 6),

                                Text(
                                  directionDetailsForTrip != null
                                      ? "Rs " +
                                            helperFunctions
                                                .fareAmountCalculation(
                                                  directionDetailsForTrip!,
                                                  "CarX",
                                                )
                                      : "fetching...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  /*"\$ 25.00",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),*/
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 1,
                            height: 60,
                            color: Colors.grey.shade400,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),

                          ///CARXL
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                appState = "requesting";
                              });

                              showWaitingContainer(
                                helperFunctions.fareAmountCalculation(
                                  directionDetailsForTrip!,
                                  "CarXL",
                                ),
                              );

                              nearestOnlineDriversList =
                                  DriverFunctions.nearestOnlineDriversList;

                              findDriverBasedOnCarType("CarXL");
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 50,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: AssetImage(
                                        "assets/images/uberxl.png",
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                Text(
                                  "CarXL",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 6),

                                Text(
                                  directionDetailsForTrip != null
                                      ? "Rs " +
                                            helperFunctions
                                                .fareAmountCalculation(
                                                  directionDetailsForTrip!,
                                                  "CarXL",
                                                )
                                      : "fetching...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  /*"\$ 30.00",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),*/
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 1,
                            height: 60,
                            color: Colors.grey.shade400,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),

                          ///CARXL
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                appState = "requesting";
                              });

                              showWaitingContainer(
                                helperFunctions.fareAmountCalculation(
                                  directionDetailsForTrip!,
                                  "CarXL",
                                ),
                              );

                              nearestOnlineDriversList =
                                  DriverFunctions.nearestOnlineDriversList;

                              findDriverBasedOnCarType("CarXL");
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 50,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: AssetImage(
                                        "assets/images/uberxl.png",
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                Text(
                                  "CarXL",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 6),

                                Text(
                                  directionDetailsForTrip != null
                                      ? "Rs " +
                                            helperFunctions
                                                .fareAmountCalculation(
                                                  directionDetailsForTrip!,
                                                  "CarXL",
                                                )
                                      : "fetching...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  /* "\$ 30.00",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),*/
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 1,
                            height: 60,
                            color: Colors.grey.shade400,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),

                          ///CARSUV
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                appState = "requesting";
                              });

                              showWaitingContainer(
                                helperFunctions.fareAmountCalculation(
                                  directionDetailsForTrip!,
                                  "CarSUV",
                                ),
                              );

                              nearestOnlineDriversList =
                                  DriverFunctions.nearestOnlineDriversList;

                              findDriverBasedOnCarType("CarSUV");
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 50,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: AssetImage(
                                        "assets/images/uberSUV.png",
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                Text(
                                  "CarSUV",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 6),

                                Text(
                                  directionDetailsForTrip != null
                                      ? "Rs " +
                                            helperFunctions
                                                .fareAmountCalculation(
                                                  directionDetailsForTrip!,
                                                  "CarSUV",
                                                )
                                      : "fetching...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  /*"\$ 35.00",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),*/
                                ),
                              ],
                            ),
                          ),

                          Container(
                            width: 1,
                            height: 60,
                            color: Colors.grey.shade400,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),

                          ///SPORTSCAR
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                appState = "requesting";
                              });

                              showWaitingContainer(
                                helperFunctions.fareAmountCalculation(
                                  directionDetailsForTrip!,
                                  "SportsCar",
                                ),
                              );

                              nearestOnlineDriversList =
                                  DriverFunctions.nearestOnlineDriversList;

                              findDriverBasedOnCarType("SportsCar");
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 120,
                                  height: 50,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    image: DecorationImage(
                                      image: AssetImage(
                                        "assets/images/sportscar.png",
                                      ),
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),

                                Text(
                                  "SportsCar",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  /* directionDetailsForTrip != null ?
                                  "\$ " + helperFunctions.fareAmountCalculation(directionDetailsForTrip!, "SportsCar") : "fetching...",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),*/
                                  "\$ 50.00",
                                  style: TextStyle(
                                    fontSize: 16,
                                    letterSpacing: 2,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    //car types list
                    Divider(thickness: 1, color: Colors.grey),

                    Text(
                      (directionDetailsForTrip != null)
                          ? "Distance = ${directionDetailsForTrip!.distance}"
                          : "fetching...",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Divider(thickness: 1, color: Colors.grey),

                    Text(
                      (directionDetailsForTrip != null)
                          ? "Duration = ${directionDetailsForTrip!.duration}"
                          : "fetching...",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Divider(thickness: 1, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),

          ///WAITING FOR RIDE - ANIMATION - CONTAINER
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: waitingForRideContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16.0,
                    spreadRadius: 0.6,
                    offset: Offset(0.65, 0.65),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 12),
                    //loading animation widget from loading_animation_widget package
                    SizedBox(
                      width: 202,
                      child: LoadingAnimationWidget.staggeredDotsWave(
                        color: Colors.green,
                        size: 49,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      "Searching a Driver for you",
                      style: TextStyle(color: Colors.white70),
                    ),

                    SizedBox(height: 20),
                    //for canceling the ride request and also
                    //clearing the google map from any markers,
                    // polylines, circles and also deleting the
                    // ride request data from firebase realtime database
                    GestureDetector(
                      onTap: () {
                        clearGoogleMap();
                        deleteRideRequest();
                        Restart.restartApp();
                      },
                      child: Container(
                        height: 49,
                        width: 49,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(width: 1.5, color: Colors.black),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          ///TRIP DETAILS INFO CONTAINER
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: tripAcceptedDetailsContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white24,
                    blurRadius: 13.0,
                    spreadRadius: 0.6,
                    offset: Offset(0.66, 0.66),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 5),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayTripStatus,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 19),

                    Divider(height: 1, color: Colors.grey, thickness: 1),

                    SizedBox(height: 19),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            helperFunctions.dialPhoneNumber(driverPhoneNumber);
                          },
                          child: Icon(
                            Icons.phone_iphone,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),

                        SizedBox(width: 14),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),

                            Text(
                              driverCarDetails,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 19),

                    Divider(height: 1, color: Colors.grey, thickness: 1),

                    SizedBox(height: 19),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
