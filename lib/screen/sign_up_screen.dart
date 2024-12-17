import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kongkon_app_driver/shared/theme.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

final _nameController = TextEditingController();
final _emailController = TextEditingController();
final _passwordController = TextEditingController();
final _licenseController = TextEditingController();
final _phoneController = TextEditingController();

class _SignUpScreenState extends State<SignUpScreen> {
  Future<void> register() async {
    final url = Uri.parse('http://192.168.18.25:3333/api/v1/users/drivers');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'license_number': _licenseController.text,
        'password': _passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      // Registration successful, show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration successful!')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Registration failed, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget header() {
      return Container(
        margin: const EdgeInsets.only(top: 30),
        width: 80,
        height: 80,
        decoration: const BoxDecoration(
            image: DecorationImage(image: AssetImage('assets/dark-logo.png'))),
      );
    }

    Widget title() {
      return Container(
        margin: const EdgeInsets.only(top: 40, left: 50),
        child: Text(
          'Join Us as\nour Partner ',
          style: blackTextStyle.copyWith(fontSize: 24, fontWeight: semibold),
        ),
      );
    }

    Widget inputSection() {
      Widget nameInput() {
        return Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Full Name'),
              const SizedBox(
                height: 6,
              ),
              TextFormField(
                controller: _nameController,
                cursorColor: kBlackColor,
                decoration: InputDecoration(
                  hintText: ' Your full name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultRadius)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    borderSide: BorderSide(color: kPrimaryColor),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      Widget emailInput() {
        return Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Email Address'),
              const SizedBox(
                height: 6,
              ),
              TextFormField(
                controller: _emailController,
                cursorColor: kBlackColor,
                decoration: InputDecoration(
                  hintText: 'Your email',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultRadius),
                      borderSide: BorderSide(color: kGreyColor)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    borderSide: BorderSide(color: kPrimaryColor),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      Widget passwordInput() {
        return Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Password'),
              const SizedBox(
                height: 6,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                cursorColor: kBlackColor,
                decoration: InputDecoration(
                  hintText: ' Your password',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultRadius)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    borderSide: BorderSide(color: kPrimaryColor),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      Widget licenseInput() {
        return Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('License Number'),
              const SizedBox(
                height: 6,
              ),
              TextFormField(
                controller: _licenseController,
                cursorColor: kBlackColor,
                decoration: InputDecoration(
                  hintText: ' Your license',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultRadius)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    borderSide: BorderSide(color: kPrimaryColor),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      Widget phoneInput() {
        return Container(
          margin: EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phone Number'),
              const SizedBox(
                height: 6,
              ),
              TextFormField(
                controller: _phoneController,
                cursorColor: kBlackColor,
                decoration: InputDecoration(
                  hintText: ' Your phone number',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(defaultRadius)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    borderSide: BorderSide(color: kPrimaryColor),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      Widget submitButton() {
        return Container(
          margin: EdgeInsets.only(top: 20),
          width: double.infinity,
          height: 45,
          child: TextButton(
              onPressed: () {
                register();
              },
              style: TextButton.styleFrom(
                backgroundColor: kPrimaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(defaultRadius)),
              ),
              child: Text(
                'Register',
                style:
                    whiteTextStyle.copyWith(fontSize: 18, fontWeight: medium),
              )),
        );
      }

      return Container(
        margin: EdgeInsets.only(top: 30),
        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 30),
        decoration: BoxDecoration(
            color: kWhiteColor,
            borderRadius: BorderRadius.circular(defaultRadius)),
        child: Column(
          children: [
            nameInput(),
            emailInput(),
            passwordInput(),
            licenseInput(),
            phoneInput(),
            submitButton(),
            Container(
              margin: EdgeInsets.only(top: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Sudah Punya Akun ? ",
                      style: blackTextStyle.copyWith(
                        fontSize: 14,
                        fontWeight: regular,
                      )),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text("Login",
                        style: blackTextStyle.copyWith(
                          fontSize: 14,
                          fontWeight: medium,
                        )),
                  )
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: ListView(
          children: [header(), title(), inputSection()],
        ),
      ),
    );
  }
}
