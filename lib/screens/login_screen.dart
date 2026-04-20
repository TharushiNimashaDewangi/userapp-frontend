import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_app_frontend/helper/helper_functions.dart';
import 'package:user_app_frontend/widgets/custom_text_field.dart';
import 'package:user_app_frontend/screens/signup_screen.dart';
import 'package:user_app_frontend/screens/home_screen.dart';
import 'package:user_app_frontend/widgets/form_validator.dart';
import 'package:user_app_frontend/widgets/snackbar.dart';
import 'package:user_app_frontend/widgets/loading_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  HelperFunctions helperFunctions = HelperFunctions();

  void loginFormValidation() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      displaySnackBar("All fields are required.", context);
    } else if (!FormValidator.isValidEmail(email)) {
      displaySnackBar("Email format is invalid.", context);
    } else if (!FormValidator.isValidPassword(password)) {
      displaySnackBar("Password must be at least 6 characters.", context);
    } else {
      loginUser();
    }
  }

  //Future<void>
  loginUser() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => LoadingDialog(),
    );

    try {
      final User? fbUser =
          (await FirebaseAuth.instance
                  .signInWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  )
                  .catchError((onErrorOccurred) {
                    displaySnackBar(onErrorOccurred.toString(), context);
                    Navigator.pop(context);
                    return onErrorOccurred;
                  }))
              .user;
      String response = await helperFunctions.retrieveUserData(context);

      if (response == "error") {
        displaySnackBar("Try again with correct email and password.", context);
        Navigator.pop(context);
      } else {
        displaySnackBar(
          "You are Logged-in Successfully. Hurrah, you can make Trip Requests now.",
          context,
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (c) => HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (exp) {
      displaySnackBar(exp.toString(), context);
      FirebaseAuth.instance.signOut();
      Navigator.pop(context);
    }
  }

  //below code line replace by helper class -> retrieveUserData
  /*DatabaseReference userReference = FirebaseDatabase.instance
          .ref()
          .child("allUsers")
          .child(fbUser!.uid);*/
  /*await userReference.once().then((onValue) {
        if (onValue.snapshot.value != null) {
          nameOfUser = (onValue.snapshot.value as Map)['name'] ?? '';
          phoneOfUser = (onValue.snapshot.value as Map)['phone'] ?? '';
          emailOfUser = (onValue.snapshot.value as Map)['email'] ?? '';
          displaySnackBar(
            "You are Logged-in Successfully. Hurrah, you can make Trip Requests now.",
            context,
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => HomeScreen()),
          ); */
  /* } else {
          displaySnackBar("No user record found for this email.", context);
          FirebaseAuth.instance.signOut();
          Navigator.pop(context);
        }

        //Navigator.push(
        //   context,
        // MaterialPageRoute(builder: (c) => HomeScreen()),
        //);
      });*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Image.asset(
            'assets/images/userapplogo.png',
            width: MediaQuery.of(context).size.width * 0.7,
          ),
          SizedBox(height: 12),
          Text(
            "Login as a user",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontFamily: 'MontserratBold',
              color: Colors.white70,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
            child: Column(
              children: [
                CustomTextField(
                  controller: emailController,
                  label: 'User Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 24),
                CustomTextField(
                  controller: passwordController,
                  label: 'User Password',
                  isPassword: true,
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: loginFormValidation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 80,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'MontserratBold',
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => SignUpScreen()),
              );
            },

            child: Text(
              "Don't have an account? Register here.",
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'MontserratRegular',
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
