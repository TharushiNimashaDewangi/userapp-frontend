import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:user_app_frontend/widgets/custom_text_field.dart';
import 'package:user_app_frontend/screens/login_screen.dart';
import 'package:user_app_frontend/widgets/form_validator.dart';
import 'package:user_app_frontend/widgets/snackbar.dart';
import 'package:user_app_frontend/widgets/loading_dialog.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();

  void signupFormValidation() {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      displaySnackBar("All fields are required.", context);
    } else if (!FormValidator.isValidName(name)) {
      displaySnackBar("Name must be at least 4 characters.", context);
    } else if (!FormValidator.isValidPhone(phone)) {
      displaySnackBar("Phone number must be at least 6 digits.", context);
    } else if (!FormValidator.isValidEmail(email)) {
      displaySnackBar("Invalid email format.", context);
    } else if (!FormValidator.isValidPassword(password)) {
      displaySnackBar("Password must be at least 6 characters.", context);
    } else {
      createUserAccount();
    }
  }

  Future<void> createUserAccount() async {
    // TODO: Implement user account creation logic (API call, Firebase, etc.)
   showDialog(
        context: context,
        builder: (BuildContext context) => LoadingDialog()
    );

    try {
      // TODO: Implement user account creation logic (API call, Firebase, etc.)
      final User? fbUser =
          (await FirebaseAuth.instance
                  .createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password: passwordController.text.trim(),
                  )
                  .catchError((onErrorOccured) {
                    displaySnackBar(onErrorOccured.toString(), context);
                    return onErrorOccured;
                  }))
              .user;
              Map dateOfUser = {
                "uid": fbUser!.uid,
                "email": emailController.text.trim(),
                "name": nameController.text.trim(),
                "phone": phoneController.text.trim(),
              };
              FirebaseDatabase.instance.ref("allUsers").child(fbUser.uid).set(dateOfUser);// data function
              displaySnackBar("Your Account Created Successfully. Please Login Now.", context);

              FirebaseAuth.instance.signOut();

              Navigator.push(context, MaterialPageRoute(builder: (c)=> LoginScreen()));
    } on FirebaseAuthException catch (exp) {
      displaySnackBar(exp.toString(), context);
      FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        children: [
          Image.asset(
            "assets/images/userapplogo.png",
            width: MediaQuery.of(context).size.width * 0.7,
          ),

          SizedBox(height: 12),

          Text(
            "Create New Account\nas a User",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontFamily: "MontserratBold",
              color: Colors.white70,
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24),
            child: Column(
              children: [
                CustomTextField(controller: nameController, label: "User Name"),

                SizedBox(height: 24),

                CustomTextField(
                  controller: phoneController,
                  label: "User Phone",
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: 24),

                CustomTextField(
                  controller: emailController,
                  label: "User Email",
                  keyboardType: TextInputType.emailAddress,
                ),

                SizedBox(height: 24),

                CustomTextField(
                  controller: passwordController,
                  label: "User Password",
                  isPassword: true,
                ),

                SizedBox(height: 30),

                ElevatedButton(
                  onPressed: signupFormValidation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 80,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: "MontserratBold",
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
                MaterialPageRoute(builder: (c) => LoginScreen()),
              );
            },
            child: Text("Already have an Account? Login here"),
          ),
        ],
      ),
    );
  }
}
