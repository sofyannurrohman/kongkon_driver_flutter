import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:kongkon_app_driver/shared/theme.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<Map<String, dynamic>> walletData;
  String? userId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Retrieve the userId passed via Navigator
    userId = ModalRoute.of(context)?.settings.arguments as String?;

    if (userId != null) {
      walletData = fetchWalletData(userId!);
    } else {
      walletData = Future.value({});
    }
  }

  Future<Map<String, dynamic>> fetchWalletData(String userId) async {
    final response = await http
        .get(Uri.parse('http://localhost:3333/api/v1/wallets/users/$userId'));

    if (response.statusCode == 200) {
      // Successfully fetched wallet data, parse the JSON response
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load wallet data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Wallet',
          style: whiteTextStyle,
        ),
        backgroundColor:
            kPrimaryColor, // Adding a background color to the app bar
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: walletData,
          builder: (context, snapshot) {
            // Check the status of the request
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No wallet data found',style: blackTextStyle,));
            }

            // Display the wallet data
            final data = snapshot.data!;
            return Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Wallet ID: ${data["id"]}',
                      style: blackTextStyle.copyWith(
                          fontSize: 14, fontWeight: medium),
                    ),
                    const SizedBox(height: 20),
                    Text('Rp.${data["saldo"].toStringAsFixed(2)}',
                        style: blackTextStyle.copyWith(
                            fontSize: 14, fontWeight: medium)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Created At:',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${data["createdAt"]}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Updated At:',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${data["updatedAt"]}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
