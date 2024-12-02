import 'package:flutter/material.dart';
import 'package:kongkon_app_driver/shared/theme.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget header() {
      return Container(
        margin: const EdgeInsets.only(top: 30),
        width: 80,
        height: 80,
        decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/dark-logo.png'))),
      );
    }

    Widget title() {
      return Container(
        margin: const EdgeInsets.only(top: 80, left: 20),
        child: Text('Join Us as\nour Partner ',
        style: blackTextStyle.copyWith(
          fontSize: 24,
          fontWeight: semibold
        ),),
      );
    }

    Widget inputSection(){
      return Container(
        margin: const EdgeInsets.only(top: 30),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 30
        ),
        decoration: BoxDecoration(
          color: kWhiteColor,
          border: BorderRadius.circular(defaultRadius);
        ),
        child: Column(

        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: ListView(
          children: [
            header(),
            title(),
          ],
        ),
      ),
    );
  }
}
