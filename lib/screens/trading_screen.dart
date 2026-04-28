import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_fake_bank/models/crypto_model.dart';
import 'package:my_fake_bank/widgets/trading_chart.dart';

class FutureTradingScreen extends StatefulWidget {
  final String symbol;
  const FutureTradingScreen({super.key, required this.symbol});

  @override
  State<FutureTradingScreen> createState() => _FutureTradingScreenState();
}

class _FutureTradingScreenState extends State<FutureTradingScreen> {
  List<CandleData> chartData = [];
  String selectedTimeframe = "1m";
  double leverage = 50.0;
  double currentPrice = 0.0;
  Timer? _timer;
  final List<String> timeframes = [
    "1s",
    "1m",
    "3m",
    "5m",
    "15m",
    "30m",
    "1h",
    "4h",
    "1d"
  ];

  @override
  void initState() {
    super.initState();
    _fetchKlines();
    _timer =
        Timer.periodic(const Duration(seconds: 2), (timer) => _fetchPrice());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPrice() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.binance.com/api/v3/ticker/price?symbol=${widget.symbol}'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => currentPrice = double.parse(data['price']));
      }
    } catch (_) {}
  }

  Future<void> _fetchKlines() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.binance.com/api/v3/klines?symbol=${widget.symbol}&interval=$selectedTimeframe&limit=100'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          chartData = data
              .map((i) => CandleData(
                    x: DateTime.fromMillisecondsSinceEpoch(i[0]),
                    open: double.parse(i[1]),
                    high: double.parse(i[2]),
                    low: double.parse(i[3]),
                    close: double.parse(i[4]),
                    volume: double.parse(i[5]),
                  ))
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(backgroundColor: Colors.black, title: Text(widget.symbol)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("\$${currentPrice.toStringAsFixed(2)}",
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          _buildTimeframeBar(),
          SizedBox(height: 300, child: TradingChart(data: chartData)),
          _buildOrderPanel(),
        ],
      ),
    );
  }

  Widget _buildTimeframeBar() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: timeframes.length,
        itemBuilder: (context, index) => GestureDetector(
          onTap: () {
            setState(() => selectedTimeframe = timeframes[index]);
            _fetchKlines();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(timeframes[index],
                style: TextStyle(
                    color: selectedTimeframe == timeframes[index]
                        ? Colors.amber
                        : Colors.grey,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderPanel() {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
            color: Color(0xFF1E2329),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Đòn bẩy", style: TextStyle(color: Colors.grey)),
                Text("${leverage.toInt()}x",
                    style: const TextStyle(
                        color: Colors.amber, fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: leverage,
              min: 1,
              max: 500,
              activeColor: Colors.amber,
              onChanged: (v) => setState(() => leverage = v),
            ),
            const Spacer(),
            Row(
              children: [
                _tradeBtn("Long", Colors.greenAccent),
                const SizedBox(width: 16),
                _tradeBtn("Short", Colors.redAccent),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _tradeBtn(String label, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 16)),
        child: Text(label,
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
