import 'package:flutter/material.dart';
import 'package:user_app_frontend/screens/completed_trips_history.dart';
import 'package:user_app_frontend/user_info.dart';
import 'package:user_app_frontend/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';


class UserDrawer extends StatefulWidget {
  const UserDrawer({super.key});

  @override
  State<UserDrawer> createState() => _UserDrawerState();
}

class _UserDrawerState extends State<UserDrawer> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 256,
        child: Drawer(
          backgroundColor: Colors.black87,
          child: ListView(
            children: [

              //header
              SizedBox(
                height: 160,
                child: DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/images/user_avatar.png",
                        width: 60,
                        height: 60,
                      ),

                      const SizedBox(width: 16,),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            nameOfUser,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 4,),

                          const Text(
                            "profile",
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              //body
              GestureDetector(
                onTap: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (c)=> CompletedTripsHistory()));
                },
                child: const ListTile(
                  leading: Icon(Icons.history, color: Colors.white,),
                  title: Text("History", style: TextStyle(color: Colors.white),),
                ),
              ),

              GestureDetector(
                onTap: ()
                {
                  FirebaseAuth.instance.signOut();

                  Navigator.push(context, MaterialPageRoute(builder: (c)=> LoginScreen()));
                },
                child: const ListTile(
                  leading:  Icon(Icons.logout, color: Colors.white,),
                  title: Text("Logout", style: TextStyle(color: Colors.white),),
                ),
              ),

            ],
          ),
        )
      );
  }
}