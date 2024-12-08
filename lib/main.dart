import 'package:flutter/material.dart';
import 'package:kongkon_app_driver/screen/dashboard_screen.dart';
import 'package:kongkon_app_driver/screen/login_screen.dart';
import 'package:kongkon_app_driver/screen/sign_up_screen.dart';
import 'package:kongkon_app_driver/screen/splash_screen.dart';
import 'package:kongkon_app_driver/services/geocoding_service.dart';
import 'package:kongkon_app_driver/services/socket_service.dart';
import 'package:provider/provider.dart';
import 'api/auth_provider.dart';

void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => LocationProvider()),
    ChangeNotifierProvider<SocketService>(create: (_) => SocketService()),
  ], child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kongkon Driver',
      initialRoute: '/dashboard',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => SignUpScreen(),
        '/dashboard': (context) => DashboardScreen(),
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}
