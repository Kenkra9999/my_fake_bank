import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:async';
import 'dart:math';
import '../models/crypto_data.dart';
import 'package:intl/intl.dart';

class CryptoHomeScreen extends StatefulWidget {
  const CryptoHomeScreen({Key? key}) : super(key: key);

  @override
  State<CryptoHomeScreen> createState() => _CryptoHomeScreenState();
}

class _CryptoHomeScreenState extends State<CryptoHomeScreen> {
  late Wallet wallet;
  String selectedSymbol = 'BTC/USDT';
  String selectedTimeframe = '1m';
  double currentPrice = 76080.0;
  double priceChange = -0.88;
  int selectedLeverage = 10;
  bool isLongMode = true;
  List<CandleData> chartData = [];
  TechnicalIndicators? indicators;
  List<TradePosition> positions = [];
  Timer? updateTimer;
  final TextEditingController sizeController = TextEditingController();

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
  final List<String> symbols = [
    'BTC/USDT',
    'ETH/USDT',
    'BNB/USDT',
    'SOL/USDT',
    'XRP/USDT'
  ];
  final Map<String, double> basePrices = {
    'BTC/USDT': 76080.0,
    'ETH/USDT': 2272.8,
    'BNB/USDT': 615.5,
    'SOL/USDT': 188.4,
    'XRP/USDT': 0.55,
  };

  @override
  void initState() {
    super.initState();
    wallet = Wallet();
    _generateChartData();
    _startAutoUpdate();
  }

  void _generateChartData() {
    chartData = [];
    final Random random = Random();
    DateTime now = DateTime.now();
    double price = basePrices[selectedSymbol] ?? 76080.0;

    for (int i = 59; i >= 0; i--) {
      DateTime candleTime = now.subtract(Duration(minutes: i));
      double open = price;
      double change = (random.nextDouble() - 0.5) * 200;
      double close = price + change;
      double high = max(open, close) + random.nextDouble() * 100;
      double low = min(open, close) - random.nextDouble() * 100;
      double vol = random.nextDouble() * 5000;

      chartData.add(CandleData(
        time: candleTime,
        open: open,
        high: high,
        low: low,
        close: close,
        volume: vol,
      ));
      price = close;
    }

    currentPrice = chartData.last.close;
    priceChange = ((currentPrice - basePrices[selectedSymbol]!) /
            basePrices[selectedSymbol]!) *
        100;
    indicators = TechnicalIndicators.calculate(chartData);
  }

  void _startAutoUpdate() {
    updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && chartData.isNotEmpty) {
        final Random random = Random();
        final lastCandle = chartData.last;
        final newPrice = lastCandle.close + (random.nextDouble() - 0.5) * 50;

        chartData[chartData.length - 1] = CandleData(
          time: lastCandle.time,
          open: lastCandle.open,
          high: max(lastCandle.high, newPrice),
          low: min(lastCandle.low, newPrice),
          close: newPrice,
          volume: lastCandle.volume + random.nextInt(500).toDouble(),
        );

        setState(() {
          currentPrice = newPrice;
          priceChange = ((currentPrice - basePrices[selectedSymbol]!) /
                  basePrices[selectedSymbol]!) *
              100;
          indicators = TechnicalIndicators.calculate(chartData);
        });
      }
    });
  }

  void _openPosition() {
    if (sizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter position size')),
      );
      return;
    }

    double size = double.parse(sizeController.text);
    double margin = size / selectedLeverage;

    if (isLongMode && wallet.usdtBalance < margin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance')),
      );
      return;
    }

    wallet.withdraw('USDT', margin);

    TradePosition position = TradePosition(
      id: 'POS-${DateTime.now().millisecondsSinceEpoch}',
      symbol: selectedSymbol,
      isLong: isLongMode,
      entryPrice: currentPrice,
      size: size,
      leverage: selectedLeverage,
      margin: margin,
      openTime: DateTime.now(),
    );

    setState(() {
      positions.add(position);
      sizeController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${isLongMode ? "Long" : "Short"} position opened at \$${currentPrice.toStringAsFixed(2)}'),
        backgroundColor: isLongMode ? Colors.green : Colors.red,
      ),
    );
  }

  void _closePosition(TradePosition position) {
    setState(() {
      position.closePrice = currentPrice;
      position.closeTime = DateTime.now();
      position.isClosed = true;
      double pnl = position.pnl;
      wallet.deposit('USDT', position.margin + pnl);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Position closed. P&L: ${position.pnl > 0 ? "+" : ""}\$${position.pnl.toStringAsFixed(2)}'),
        backgroundColor: position.pnl >= 0 ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    updateTimer?.cancel();
    sizeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0E11),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12151C),
        title: Row(
          children: [
            const Icon(Icons.account_circle, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            Text(selectedSymbol,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: priceChange >= 0
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${priceChange > 0 ? "+" : ""}${priceChange.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: priceChange >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.search, color: Colors.white70),
              onPressed: () {}),
          IconButton(
              icon:
                  const Icon(Icons.headset_mic_outlined, color: Colors.white70),
              onPressed: () {}),
          IconButton(
              icon: const Icon(Icons.notifications_none, color: Colors.white70),
              onPressed: () {}),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Wallet Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF12151C),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Balance',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white54,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        wallet.usdtBalance.toStringAsFixed(2),
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text('USDT',
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600)),
                      const Icon(Icons.arrow_drop_down, color: Colors.white54),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '≈ ₫${(wallet.vndBalance).toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d)(?=(\d{3})+(?!\d))"), (m) => "${m[1]},")}',
                    style: const TextStyle(fontSize: 14, color: Colors.white38),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showDepositDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B3139),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Deposit',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showWithdrawDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Withdraw',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Timeframe Selector
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: timeframes
                            .map((tf) => Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => selectedTimeframe = tf),
                                    child: Column(
                                      children: [
                                        Text(
                                          tf,
                                          style: TextStyle(
                                            color: selectedTimeframe == tf
                                                ? Colors.white
                                                : Colors.white38,
                                            fontWeight: selectedTimeframe == tf
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (selectedTimeframe == tf)
                                          Container(
                                            margin:
                                                const EdgeInsets.only(top: 4),
                                            height: 2,
                                            width: 16,
                                            color: Colors.amber,
                                          ),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                  const Icon(Icons.bar_chart, color: Colors.white38, size: 20),
                  const SizedBox(width: 8),
                  const Icon(Icons.settings_outlined,
                      color: Colors.white38, size: 20),
                ],
              ),
            ),

            // Chart
            if (chartData.isNotEmpty && indicators != null)
              SizedBox(
                height: 400,
                width: double.infinity,
                child: SfCartesianChart(
                  margin: EdgeInsets.zero,
                  plotAreaBorderWidth: 0,
                  primaryXAxis: const DateTimeAxis(
                    isVisible: true,
                    labelStyle: TextStyle(color: Colors.white24, fontSize: 10),
                    majorGridLines: MajorGridLines(width: 0),
                    axisLine: AxisLine(width: 0),
                  ),
                  primaryYAxis: NumericAxis(
                    opposedPosition: true,
                    labelStyle:
                        const TextStyle(color: Colors.white24, fontSize: 10),
                    majorGridLines: MajorGridLines(
                      color: Colors.white.withValues(alpha: 0.05),
                      width: 0.5,
                    ),
                    axisLine: const AxisLine(width: 0),
                    numberFormat: NumberFormat.compactSimpleCurrency(
                        decimalDigits: 2, name: ""),
                  ),
                  trackballBehavior: TrackballBehavior(
                    enable: true,
                    activationMode: ActivationMode.singleTap,
                    tooltipSettings: const InteractiveTooltip(
                        enable: true, color: Color(0xFF1E2329)),
                    lineColor: Colors.white38,
                    lineWidth: 1,
                    lineType: TrackballLineType.vertical,
                  ),
                  series: <CartesianSeries>[
                    CandleSeries<CandleData, DateTime>(
                      dataSource: chartData,
                      xValueMapper: (CandleData candle, _) => candle.time,
                      lowValueMapper: (CandleData candle, _) => candle.low,
                      highValueMapper: (CandleData candle, _) => candle.high,
                      openValueMapper: (CandleData candle, _) => candle.open,
                      closeValueMapper: (CandleData candle, _) => candle.close,
                      bearColor: const Color(0xFFF6465D),
                      bullColor: const Color(0xFF0ECB81),
                      enableSolidCandles: true,
                    ),
                    LineSeries<double, DateTime>(
                      dataSource: indicators!.movingAverage,
                      xValueMapper: (_, index) => chartData[index +
                              (chartData.length -
                                  indicators!.movingAverage.length)]
                          .time,
                      yValueMapper: (val, _) => val,
                      color: Colors.amber.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    LineSeries<double, DateTime>(
                      dataSource: indicators!.bollingerUpper,
                      xValueMapper: (_, index) => chartData[index +
                              (chartData.length -
                                  indicators!.bollingerUpper.length)]
                          .time,
                      yValueMapper: (val, _) => val,
                      color: Colors.purple.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ],
                ),
              ),

            // Indicators Panel
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2329).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildIndicatorInfo('VOL',
                      '${(indicators!.volume.last / 1000).toStringAsFixed(1)}K'),
                  _buildIndicatorInfo(
                      'RSI',
                      indicators!.rsi.isNotEmpty
                          ? indicators!.rsi.last.toStringAsFixed(1)
                          : '-'),
                  _buildIndicatorInfo(
                      'MACD',
                      indicators!.macd.isNotEmpty
                          ? indicators!.macd.last.toStringAsFixed(2)
                          : '-'),
                  _buildIndicatorInfo(
                      'MA',
                      indicators!.movingAverage.isNotEmpty
                          ? indicators!.movingAverage.last.toStringAsFixed(1)
                          : '-'),
                  _buildIndicatorInfo('BOLL',
                      indicators!.bollingerUpper.isNotEmpty ? 'Active' : '-'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Trading Panel
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2329),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildTradeTab(
                          'Mở Long',
                          isLongMode,
                          () => setState(() => isLongMode = true),
                          const Color(0xFF0ECB81)),
                      const SizedBox(width: 12),
                      _buildTradeTab(
                          'Mở Short',
                          !isLongMode,
                          () => setState(() => isLongMode = false),
                          const Color(0xFFF6465D)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Đòn bẩy (Leverage)',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('${selectedLeverage}x',
                            style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: Colors.amber,
                      inactiveTrackColor: Colors.white10,
                      thumbColor: Colors.amber,
                      overlayColor: Colors.amber.withValues(alpha: 0.2),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: selectedLeverage.toDouble(),
                      min: 1,
                      max: 500,
                      divisions: 499,
                      onChanged: (val) =>
                          setState(() => selectedLeverage = val.toInt()),
                    ),
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1x',
                          style:
                              TextStyle(color: Colors.white24, fontSize: 11)),
                      Text('500x',
                          style:
                              TextStyle(color: Colors.white24, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: sizeController,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Nhập số tiền (USDT)',
                      hintStyle:
                          const TextStyle(color: Colors.white24, fontSize: 14),
                      filled: true,
                      fillColor: const Color(0xFF0B0E11),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                      suffixText: 'USDT',
                      suffixStyle: const TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.amber, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _openPosition,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isLongMode
                            ? const Color(0xFF0ECB81)
                            : const Color(0xFFF6465D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        isLongMode ? 'Mở Vị Thế Long' : 'Mở Vị Thế Short',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Active Positions
            if (positions.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Vị thế đang mở',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
              ),
              ...positions.map((pos) => _buildEnhancedPositionCard(pos)),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeTab(
      String label, bool isActive, VoidCallback onTap, Color activeColor) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeColor : const Color(0xFF0B0E11),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isActive
                    ? activeColor
                    : Colors.white.withValues(alpha: 0.05)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorInfo(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildEnhancedPositionCard(TradePosition pos) {
    double pnl = pos.pnl;
    double pnlPct = pos.pnlPercentage * pos.leverage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2329),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: pos.isLong
                          ? const Color(0xFF0ECB81).withValues(alpha: 0.1)
                          : const Color(0xFFF6465D).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      pos.isLong ? "LONG" : "SHORT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: pos.isLong
                            ? const Color(0xFF0ECB81)
                            : const Color(0xFFF6465D),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${pos.symbol} ${pos.leverage}x',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14)),
                ],
              ),
              IconButton(
                onPressed: () => _closePosition(pos),
                icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPosDetail(
                  'Giá vào', '\$${pos.entryPrice.toStringAsFixed(2)}'),
              _buildPosDetail(
                  'Giá hiện tại', '\$${currentPrice.toStringAsFixed(2)}'),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('PnL (ROE%)',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    '${pnl > 0 ? "+" : ""}\$${pnl.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: pnl >= 0
                          ? const Color(0xFF0ECB81)
                          : const Color(0xFFF6465D),
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${pnlPct > 0 ? "+" : ""}${pnlPct.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: pnlPct >= 0
                          ? const Color(0xFF0ECB81)
                          : const Color(0xFFF6465D),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _closePosition(pos),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Đóng vị thế ngay',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPosDetail(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ],
    );
  }

  void _showDepositDialog() {
    final TextEditingController amountController = TextEditingController();
    String selectedCurrency = 'USDT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F2E),
          title: const Text('Deposit', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedCurrency,
                dropdownColor: const Color(0xFF1A1F2E),
                style: const TextStyle(color: Colors.white),
                items: ['USDT', 'VND'].map<DropdownMenuItem<String>>((v) {
                  return DropdownMenuItem(value: v, child: Text(v));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedCurrency = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                double amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  setState(() => wallet.deposit(selectedCurrency, amount));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Deposited $amount $selectedCurrency'),
                        backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child:
                  const Text('Deposit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawDialog() {
    final TextEditingController amountController = TextEditingController();
    String selectedCurrency = 'USDT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1F2E),
          title: const Text('Withdraw', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: selectedCurrency,
                dropdownColor: const Color(0xFF1A1F2E),
                style: const TextStyle(color: Colors.white),
                items: ['USDT', 'VND'].map<DropdownMenuItem<String>>((v) {
                  return DropdownMenuItem(value: v, child: Text(v));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedCurrency = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                double amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  setState(() => wallet.withdraw(selectedCurrency, amount));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Withdrew $amount $selectedCurrency'),
                        backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child:
                  const Text('Withdraw', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
} // End of _CryptoHomeScreenState
