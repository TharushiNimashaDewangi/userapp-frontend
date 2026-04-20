import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as authio;
import 'package:googleapis/servicecontrol/v1.dart' as servicecontrol;
import 'package:provider/provider.dart';
import 'package:user_app_frontend/manageInfo/manage_info.dart';
import 'package:user_app_frontend/driver_info.dart';
import 'package:user_app_frontend/user_info.dart';

class PushNotificationSystem {
  //section15 for handling nearest online drivers around user 
  //location within radius 15 and also listen to that query 
  //in real time for any changes in driver location or driver 
  //online offline status and accordingly update the nearest
  // online drivers list and markers on map
  //obtain server key for FCM API using service account credentials
  static Future<String> obtainServerKey() async {
    final jsonClientIDAndSecret = {
      "type": "service_account",
      "project_id": "carpoolingandridesharing-27067",
      "private_key_id": "38feef63d089215710b514c77b6424f1404f2002",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEuwIBADANBgkqhkiG9w0BAQEFAASCBKUwggShAgEAAoIBAQCYwAdW8lMQCm5/\nJIu3Rzp8SNDp30FkeHNzmZiLV10+z9gV2oWTdhQt33000EEj0ew05JMqcFc2Qcjx\n6ff5boftL68wsvLY2QhnTNV2nL43PIkt3wA1C+56eXX12o0577VopwrYbfRt8D7j\nW/rv5YaZd8hUqPeq59SKzVZVSh4PNLP0FT+tH8CF0yfzrPrDpnYsz0JKFny45m3v\nT9lDMF0fUPJoh/t8i7rnVu62aiTUtrM0hEtaQPrND+BaaFJdQ6qcYL5Ri07xluWo\n1I5IU9TvJYcGZULTYj2ShKqc+YJ9fiYL4n+7/MKy+qNL57ghpo2xp3tK3tiWuEq6\npZiFWkz7AgMBAAECggEAE8LGmvfvHk8ggQWa/D3pvLRgL9v4W2VobNcSW0xqaBAp\na0JW2inXbcvQ0ylHPrlkmRR3pBuJHMrL591AfZ36qwjqiB6juMFIYLIZl3uq8VMS\niBhRBYvNRpOPWsadqJYbM4u7T8ksavXpR4PZuyPyvXM35m6ULnb0EcouALX9nN0d\nvxTz06xXycryH+i64Wak9eGgZKh3/OSPX/EvfFFSr1g+PNRUZxXy7EPgZOvUPFCz\n3d6lqrM8Wm67kK3e2wgb10KtHJ/in3W+IBJahIM69aPwVxUfqi+RQNSeinMKJBAu\nbaDmbPQtfGgI52ILbqjIy97W4amF7zZMeQxoP8lAyQKBgQDGX8R8RvA9zGW+iW60\nNZYvObpKgk7NJnltoWgAf6nVsS6U26CNJZpHf6DxuFFh3tigiSEk2GSRy5NOHWOS\nGyibae0tsmxA8YiHbEUkUCNBsbpSq2Fz1srhWzSPzSf5iPC6kns1w+4P8jzYiKcg\noHAd2BfhiRTwt4qYnWPCwoQEBwKBgQDFH2alpg1YusYn/2tKxKZQNqZYvzBUty0c\ngtR4EL+82C4NpKj92iX1f0dgIz1K1PJ4C7PiendbdVxiRE1sYWso0jc0aH/UvaWq\nbFVxT5IMmyVa2l8vYPDqDFwhkDDkUjJB7BAI8bqAnLk+UKADKuPHzp8RV7ulXG3E\np0KfAy06bQKBgQCgwXjj0UTcf6gv6QVqSkajjJ93w/OB8lzSx8sVJF+ICWabQQPx\nffhxWm8dk2V373QTXC0cw7N0Jsn/snc/Ln0QvJ10u7NYSaN/QvEhBUQc957rYXC+\nw+BzEUseAX4UjLGwMAZiwp1IFODUBKGTIhDZToXDwifTDpnlJR5z9NewvwJ/Y1Rv\nZQlHsG5ta7pJVmPBaqofKJkuwYGMOdGzPs0x0PcePcG7Zi+G8S4xyT/4oryrcdJz\n0qvjeTKqWtoQKYztcqR7LO17fLgTwszUQUTXU4LaT+26CSXQQB/6TO9bs7G3oYBS\nlC86y5QtxDjcaLw0C3sSrKqI48qvhWjDKV1wbQKBgBFT+/BnR/9jmqqKv7cWpGSG\n0stA6GiLkXy6hRBn/sH80uwr1Yri9RJcfnBRBJU+DlWpNPwkQWngIHZc1XIxCCxD\nnu+eln7iqyF2uAL7Fvd5ci2jmyV3hQVi6IBgEWbnEW/8F6xn/lF5naHdkLWwDoSS\na6XlwcWcBKWIQ4p6jhZz\n-----END PRIVATE KEY-----\n",
      "client_email":
          "uberclone2026@carpoolingandridesharing-27067.iam.gserviceaccount.com",
      "client_id": "103325007330669519588",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/uberclone2026%40carpoolingandridesharing-27067.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com",
    };
    //section15 for handling nearest online drivers around user location within radius 15 and also listen to that query in real time for any changes in driver location or driver online offline status and accordingly update the nearest online drivers list and markers on map
    List<String> scopes = [
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/firebase.database",
      "https://www.googleapis.com/auth/firebase.messaging",
    ];
    // Create an authenticated HTTP client using the service account 
    // credentials
    http.Client clienthttp = await authio.clientViaServiceAccount(
      authio.ServiceAccountCredentials.fromJson(jsonClientIDAndSecret),
      scopes,
    );

    // get the access token using the service account credentials
    authio.AccessCredentials accessCredentials = await authio
        .obtainAccessCredentialsViaServiceAccount(
          authio.ServiceAccountCredentials.fromJson(jsonClientIDAndSecret),
          scopes,
          clienthttp,
        );

    // Close the HTTP client
    clienthttp.close();

    // Return the access token
    return accessCredentials.accessToken.data;
  }
  //section15 for handling nearest online drivers around user location within
  // radius 15 and also listen to that query in real time for any changes 
  //in driver location or driver online offline status and accordingly update 
  //the nearest online drivers list and markers on map
  static sendNotificationToChosenDriver(
    String deviceRecognitionToken,
    BuildContext context,
    String rideID,
  ) async {
    final String keyServer = await obtainServerKey();
    print('dewwwwww -> Obtained Server Key: $keyServer');
//from doc POST https://fcm.googleapis.com/v1/{parent=projects/*}/messages:send
//{parent=projects/*} is the project id 
//of the firebase project which is carpoolingandridesharing-27067(Project ID )
//6
    String endpointFCMAPI =
        'https://fcm.googleapis.com/v1/projects/carpoolingandridesharing-27067/messages:send';
//drop off and pick up addresses to be sent in the notification body to the driver
    String dropOffDestinationAddress = Provider.of<ManageInfo>(context,listen: false,).destinationDropOff!.placeName.toString();
    String pickUpAddress = Provider.of<ManageInfo>(context,listen: false,).pickUp!.placeName.toString();
//name of user to be sent in the notification title to the driver
//create the message payload to be sent to the FCM API with device 
//recognition token, notification title and body and also data payload 
//containing ride ID
//rideID must be same as the driver app
//design cloud msg structure in a way that driver app can easily parse the 
//notification and data payload to display the notification and also
// navigate to the ride details screen when the driver taps on the 
// notification
    final Map<String, dynamic> message = {
      'message': {
        'token':
            deviceRecognitionToken, // Token of the device you want to send the message to
        'notification': {
          "title": "RIDE REQUEST from $nameOfUser",
          "body":
              "PickUp ADDRESS: $pickUpAddress \nDestination ADDRESS: $dropOffDestinationAddress",
        },
        'data': {"rideID": rideID},
      },
    };
//call the FCM API to send the message to the chosen driver using 
//the device recognition token and the server key obtained from 
//service account credentials
    final http.Response responseFromFCMAPI = await http.post(
      Uri.parse(endpointFCMAPI),
      headers: <String, String>{//define headers for the FCM API call with content type and authorization using the server key
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $keyServer',// Use the obtained server key as a Bearer token for authorization
      },
      body: jsonEncode(message),
    );

    if (responseFromFCMAPI.statusCode == 200) {
      print('GOOD. FCM message sent successfully.');
    } else {
      print(
        'OOPS. Failed to send FCM message: ${responseFromFCMAPI.statusCode}',
      );
    }
  }
}
