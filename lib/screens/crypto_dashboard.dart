import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CryptoDashboard extends StatefulWidget {
  const CryptoDashboard({super.key});

  @override
  State<CryptoDashboard> createState() => _CryptoDashboardState();
}

class _CryptoDashboardState extends State<CryptoDashboard> {
  double usdtBalance = 0.0;
  final int rate = 25450; // Tỷ giá giả định

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      usdtBalance = prefs.getDouble('usdt_balance') ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Giao dịch Futures",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Wallet Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2329),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Tổng số dư",
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 10),
                Text("${usdtBalance.toStringAsFixed(2)} USDT",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
                Text("≈ ${(usdtBalance * rate).toInt()} VND",
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _actionBtn("Nạp tiền", Colors.greenAccent, Icons.add),
                    const SizedBox(width: 12),
                    _actionBtn("Rút tiền", Colors.white24, Icons.outbox),
                  ],
                )
              ],
            ),
          ),
          // Market List (Ví dụ BTC)
          Expanded(
            child: ListView(
              children: [
                _marketItem("BTC/USDT", "76,083.2", "-0.88%"),
                _marketItem("ETH/USDT", "2,272.8", "-0.03%"),
                _marketItem("SOL/USDT", "83.33", "-0.91%"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color:
                    color == Colors.greenAccent ? Colors.black : Colors.white),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color == Colors.greenAccent
                        ? Colors.black
                        : Colors.white,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _marketItem(String pair, String price, String change) {
    return ListTile(
      onTap: () {}, // Navigation to Trading Screen
      title: Text(pair,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(price,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          Text(change,
              style: TextStyle(
                  color:
                      change.contains("-") ? Colors.red : Colors.greenAccent)),
        ],
      ),
    );
  }
}
