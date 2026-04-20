import '../models/nearest_online_drivers.dart';
//this class is used to update the nearest online drivers 
//list and markers on map in real time when any driver
// is moving around user location within radius 15 
//or when any driver go outside from radius
// 15 around user location or when any driver 
//become online or become offline
class DriverFunctions {
  static List<NearestOnlineDrivers> nearestOnlineDriversList = [];

  static void updateNearestOnlineDriversLocation(NearestOnlineDrivers nearestOnlineDriverInfo)
  {
    int index = nearestOnlineDriversList.indexWhere((driver) => driver.driverKey == nearestOnlineDriverInfo.driverKey);

    nearestOnlineDriversList[index].driverLatitude = nearestOnlineDriverInfo.driverLatitude;
    nearestOnlineDriversList[index].driverLongitude = nearestOnlineDriverInfo.driverLongitude;
  }
//this function is used to add new driver to the nearest online drivers list
  static void deleteDriverFromList(String exitedDriverKey)
  {
    int index = nearestOnlineDriversList.indexWhere((driver) => driver.driverKey == exitedDriverKey);

    if(nearestOnlineDriversList.isNotEmpty)
    {
      nearestOnlineDriversList.removeAt(index);
    }
  }
}