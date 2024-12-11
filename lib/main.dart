import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kongkon_app_driver/api/current_location.dart';
import 'package:kongkon_app_driver/screen/dashboard_screen.dart';
import 'package:kongkon_app_driver/screen/login_screen.dart';
import 'package:kongkon_app_driver/screen/sign_up_screen.dart';
import 'package:kongkon_app_driver/screen/splash_screen.dart';
import 'package:kongkon_app_driver/screen/wallet_screen.dart';
import 'package:kongkon_app_driver/services/geocoding_service.dart';
import 'package:kongkon_app_driver/services/order_service.dart';
import 'package:kongkon_app_driver/services/socket_service.dart';
import 'package:provider/provider.dart';
import 'api/auth_provider.dart';

void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => LocationProvider()),
    ChangeNotifierProvider<SocketService>(create: (_) => SocketService()),
    ChangeNotifierProvider(
      create: (context) => OrderProvider(),
    ),
    ChangeNotifierProvider(
      create: (_) => LocationToggleProvider(),
    ),
  ], child: MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kongkon Driver',
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => SignUpScreen(),
        '/dashboard': (context) => DashboardScreen(),
        '/wallet': (context) => WalletScreen(),
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginScreen(),
    );
  }
}

class AppInitScreen extends StatefulWidget {
  @override
  _AppInitScreenState createState() => _AppInitScreenState();
}

class _AppInitScreenState extends State<AppInitScreen> {
  @override
  void initState() {
    super.initState();
    checkIfLoggedIn();
  }

  Future<void> checkIfLoggedIn() async {
    final FlutterSecureStorage _storage = FlutterSecureStorage();

    // Retrieve the saved token and user ID from Secure Storage
    String? token = await _storage.read(key: 'access_token');
    String? userId = await _storage.read(key: 'user_id');

    if (token != null && userId != null) {
      // User is logged in, navigate to the Dashboard screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else {
      // User is not logged in, navigate to the Login screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator or splash screen while checking login status
    return Scaffold(
      body: Center(
        child:
            CircularProgressIndicator(), // A loading spinner until check is done
      ),
    );
  }
}
