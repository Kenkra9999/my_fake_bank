import 'package:flutter/material.dart';
import '../widgets/trading_chart.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key});

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  // Các khung thời gian theo yêu cầu
  final List<String> timeframes = [
    '1s',
    '1m',
    '3m',
    '5m',
    '15m',
    '30m',
    '1h',
    '2h',
    '4h',
    '1d'
  ];
  String selectedTimeframe = '15m';

  // Đòn bẩy tối đa 500x
  double leverage = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFF121418), // Nền dark mode cực sâu và sang trọng
      appBar: AppBar(
        backgroundColor: const Color(0xFF181A20),
        title: const Text(
          'BTC/USDT',
          style: TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWalletBalance(),
              const SizedBox(height: 8),
              _buildTimeframeBar(),
              const SizedBox(height: 8),
              _buildChartArea(),
              _buildIndicatorsToggle(),
              _buildLeverageSlider(),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Giao diện Ví & Số dư (Rất gọn gàng, chỉ có USDT và VND cùng 2 nút Nạp/Rút)
  Widget _buildWalletBalance() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF181A20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Total Balance',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  SizedBox(height: 6),
                  Text('14,582.50 USDT',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text('≈ 364,562,500 VND',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {}, // Thêm logic Deposit
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0ECB81), // Xanh lá crypto
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Deposit',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {}, // Thêm logic Withdraw
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF6465D), // Đỏ crypto
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Withdraw',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Thanh Timeframes
  Widget _buildTimeframeBar() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: timeframes.length,
        itemBuilder: (context, index) {
          final tf = timeframes[index];
          final isSelected = tf == selectedTimeframe;
          return GestureDetector(
            onTap: () => setState(() => selectedTimeframe = tf),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color:
                    isSelected ? const Color(0xFF2B3139) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                tf,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // 3. Khu vực Biểu đồ
  Widget _buildChartArea() {
    return Container(
      height: 380,
      width: double.infinity,
      color: const Color(0xFF181A20),
      // Gọi widget TradingChartWidget từ file trading_chart.dart
      child: const TradingChartWidget(),
    );
  }

  // 4. 5 Chỉ báo kỹ thuật (Volume, RSI, MACD, EMA, BOLL)
  Widget _buildIndicatorsToggle() {
    final indicators = ['Volume', 'RSI', 'MACD', 'EMA', 'BOLL'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: indicators.map((ind) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2B3139),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(ind,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
          );
        }).toList(),
      ),
    );
  }

  // 5. Thanh trượt đòn bẩy (Leverage up to 500x)
  Widget _buildLeverageSlider() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Adjust Leverage',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3A63A).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${leverage.toInt()}x',
                  style: const TextStyle(
                      color: Color(0xFFF3A63A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFF3A63A),
              inactiveTrackColor: const Color(0xFF2B3139),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFF3A63A).withOpacity(0.2),
            ),
            child: Slider(
              value: leverage,
              min: 1,
              max: 500,
              divisions: 500,
              onChanged: (val) => setState(() => leverage = val),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('1x', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text('500x', style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          )
        ],
      ),
    );
  }
}
