import 'package:flutter/cupertino.dart';
import 'package:user_app_frontend/models/address.dart';
//ChangeNotifier is a class provided by the Flutter framework that allows you to manage and notify listeners about changes in your application's state. It is commonly used in conjunction with the Provider package to create a reactive state management solution. When you extend ChangeNotifier, you can call notifyListeners() whenever there is a change in the state, and any widgets that are listening to this notifier will be rebuilt to reflect the new state.
class ManageInfo extends ChangeNotifier {
  Address? pickUp;
  Address? destinationDropOff;

  void updatePickUpAddress(Address pickUpAddress) {
    pickUp = pickUpAddress;
    notifyListeners();
  }

  void updateDestinationDropOffAddress(Address dropOffAddress) {
    destinationDropOff = dropOffAddress;
    notifyListeners();
  }
}
