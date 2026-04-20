import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:user_app_frontend/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_app_frontend/screens/home_screen.dart';
import 'package:user_app_frontend/manageInfo/manage_info.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //1. Ensures that the Flutter engine is fully initialized before running the app. This is necessary when you need to perform asynchronous operations (like initializing Firebase) before the app starts.
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ManageInfo(),
      child: MaterialApp(
        title: 'Users App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'MontserratRegular',
          brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark().copyWith(
          primary: Colors.white, //text and icon color
          secondary: Colors
              .grey, //accent color for buttons and other interactive elements
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white), // Default text color
          bodyLarge: TextStyle(color: Colors.white), // Large text color
          titleLarge: TextStyle(color: Colors.white), // Title text color
          //headlineMedium: TextStyle(color: Colors.white), // Headline text color
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[900], // Button background color
            foregroundColor: Colors.white, // Button text color
          ),
        ),
        ),
        home: FirebaseAuth.instance.currentUser == null ? LoginScreen() : HomeScreen(),
      )
    );
  }
}
