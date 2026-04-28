import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';

class TradingChartWidget extends StatefulWidget {
  const TradingChartWidget({Key? key}) : super(key: key);

  @override
  _TradingChartWidgetState createState() => _TradingChartWidgetState();
}

class _TradingChartWidgetState extends State<TradingChartWidget> {
  List<Candle> candles = [];
  bool themeIsDark = true;

  @override
  void initState() {
    super.initState();
    _loadMockData();
  }

  // Khởi tạo data giả định để hiển thị Chart đẹp ngay khi build
  void _loadMockData() {
    // Trong thực tế, bạn sẽ fetch data qua API của Binance hoặc các sàn khác.
    // Đây là data mockup để tạo hình nến minh họa.
    DateTime now = DateTime.now();
    setState(() {
      candles = List.generate(100, (index) {
        double base = 65000.0 + (index * 10);
        return Candle(
          date: now.subtract(Duration(minutes: 100 - index)),
          high: base + 150,
          low: base - 100,
          open: base,
          close: base + (index % 2 == 0 ? 50 : -20),
          volume: 1000.0 + (index * 5),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C087)),
      );
    }

    return Candlesticks(
      candles: candles,
      // Đã xóa bullLabel và bearLabel
    );
  }
}
