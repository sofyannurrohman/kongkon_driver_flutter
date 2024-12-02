import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kongkon_app_driver/shared/theme.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(
          context, '/login'); // Navigate to login screen
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor, // Purple background
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 200,
            height: 200,
            decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage('assets/logo-driver.png'))),
          )
        ] // Assuming logo is stored in the 'assets' folder
            ),
      ),
    );
  }
}
