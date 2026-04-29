import 'package:flutter/material.dart';
import 'screens/crypto_home_screen.dart';

void main() {
  runApp(const CryptoTradingApp());
}

class CryptoTradingApp extends StatelessWidget {
  const CryptoTradingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crypto Trading Pro',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F1419),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1F2E),
          elevation: 0,
        ),
      ),
      home: const CryptoHomeScreen(),
    );
  }
}
